#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
name=${1:-snapshot-$(date -u +%Y%m%dT%H%M%S)}
[[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { message 'ERROR: invalid backup name.' >&2; exit 2; }
destination="$ROOT/artifacts/backups/$name"
[[ ! -e "$destination" ]] || { message 'ERROR: backup already exists.' >&2; exit 2; }
mkdir -p "$destination"
owned_maintenance=0
cleanup() {
  if [[ "$owned_maintenance" == 1 ]]; then wp maintenance-mode deactivate || true; fi
}
trap cleanup EXIT
if ! wp maintenance-mode is-active >/dev/null 2>&1; then
  wp maintenance-mode activate
  owned_maintenance=1
fi
message "Exporting SQL, uploads and application files to $destination."
wp --skip-plugins --skip-themes db export - --quiet --single-transaction --add-drop-table --skip-comments > "$destination/database.sql"
wp eval-file /lab/scripts/php/inventory.php > "$destination/content.json"
wp eval-file /lab/scripts/php/versions.php > "$destination/versions.json"
upload_hash > "$destination/uploads.sha256"
dc exec -T wordpress tar -czf - -C /var/www/html/wp-content/uploads . > "$destination/uploads.tar.gz"
dc exec -T wordpress tar --exclude='./wp-content/uploads' --exclude='./wp-content/debug.log' --exclude='./.maintenance' -czf - -C /var/www/html . > "$destination/files.tar.gz"
printf '%s\n' "$LAB_PROJECT" > "$destination/source-project.txt"
(cd "$destination" && sha256sum database.sql content.json versions.json uploads.sha256 uploads.tar.gz files.tar.gz source-project.txt > SHA256SUMS)
touch "$destination/complete"
message 'Backup complete; checksums and content inventory were written.'
