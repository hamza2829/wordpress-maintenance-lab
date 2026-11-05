#!/usr/bin/env bash
# Shared helpers for disposable lab projects only.
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lab.env
source "$ROOT/lab.env"
export CORE_OLD CORE_TARGET PLUGIN_OLD PLUGIN_TARGET PARENT_THEME LAB_ADMIN LAB_PASSWORD LAB_EMAIL
export LAB_PROJECT=${LAB_PROJECT:-wmlab}
export LAB_PORT=${LAB_PORT:-8080}
export LAB_DB_PORT=${LAB_DB_PORT:-3307}
if [[ ! "$LAB_PROJECT" =~ ^wml[a-z0-9_-]+$ || ! "$LAB_PORT" =~ ^[0-9]+$ || ! "$LAB_DB_PORT" =~ ^[0-9]+$ ]]; then
  printf 'ERROR: invalid disposable lab project or port.\n' >&2
  exit 2
fi
URL="http://127.0.0.1:$LAB_PORT"
export ROOT URL
mkdir -p "$ROOT/artifacts" "$ROOT/.runtime"
chmod 0777 "$ROOT/artifacts"
dc() { docker compose --project-directory "$ROOT" -f "$ROOT/compose.yaml" -p "$LAB_PROJECT" "$@"; }
wp() { dc run --rm -T cli wp --url="$URL" "$@"; }
message() { printf '[%s] %s\n' "$LAB_PROJECT" "$*"; }
deactivate_maintenance() {
  if wp maintenance-mode is-active >/dev/null 2>&1; then
    wp maintenance-mode deactivate
  else
    message 'Maintenance mode is already inactive.'
  fi
}
wait_files() {
  local attempt
  for attempt in {1..60}; do
    if dc exec -T wordpress test -f /var/www/html/wp-includes/version.php; then return 0; fi
    message "Waiting for WordPress files ($attempt/60)."
    sleep 2
  done
  message 'ERROR: WordPress files did not become ready.' >&2
  return 1
}
upload_hash() {
  dc exec -T wordpress sh -c 'cd /var/www/html/wp-content/uploads && find . -type f -print0 | sort -z | xargs -0 -r sha256sum'
}
