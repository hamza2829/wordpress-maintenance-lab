#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
exec 9>"$ROOT/.runtime/$LAB_PROJECT-update.lock"
flock -n 9 || { message 'ERROR: another update is running.' >&2; exit 3; }
snapshot="pre-update-$(date -u +%Y%m%dT%H%M%S)-$$"
backup="$ROOT/artifacts/backups/$snapshot"
rollback() {
  trap - ERR
  message 'ERROR: update or check failed. Rolling back the complete snapshot.' >&2
  dc logs --no-color wordpress > "$ROOT/artifacts/update-failure-docker.log" 2>&1 || true
  if [[ -f "$backup/complete" ]] && bash "$SCRIPT_DIR/restore.sh" "$backup" --in-place && bash "$SCRIPT_DIR/checks.sh" rollback; then
    message 'Rollback completed and browser checks passed. Returning expected failure code 20.'
    exit 20
  fi
  message 'ERROR: rollback verification failed. Returning 21.' >&2
  exit 21
}
trap rollback ERR
message 'Checking the current site and listing available updates.'
bash "$SCRIPT_DIR/quick-check.sh"
bash "$SCRIPT_DIR/list-updates.sh"
bash "$SCRIPT_DIR/backup.sh" "$snapshot"
wp maintenance-mode activate
message "Updating core to $CORE_TARGET, then its database schema."
wp core update --version="$CORE_TARGET"
wp core update-db
message 'Updating the external demo plugin, then the parent theme.'
wp plugin update hello-dolly
wp theme update "$PARENT_THEME"
if [[ "${LAB_INJECT_FAILURE:-0}" == 1 ]]; then
  message 'Injecting an intentional PHP failure for the rollback test.'
  dc run --rm -T --user 0:0 --entrypoint sh cli -c 'cp /lab/tests/fixtures/broken-plugin.php /var/www/html/wp-content/plugins/nordlicht-lab/nordlicht-lab.php'
  dc exec -T wordpress rm -f /var/www/html/.maintenance
else
  deactivate_maintenance
fi
dc restart wordpress
bash "$SCRIPT_DIR/quick-check.sh"
bash "$SCRIPT_DIR/checks.sh" updated
wp eval-file /lab/scripts/php/versions.php > "$ROOT/artifacts/versions-after.json"
trap - ERR
message 'Updates complete. Browser and PHP checks passed.'
