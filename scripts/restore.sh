#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
[[ $# == 2 ]] || { message 'Usage: restore.sh BACKUP --clean|--in-place' >&2; exit 2; }
backup=$(realpath "$1")
mode=$2
[[ "$backup" == "$ROOT/artifacts/backups/"* && -f "$backup/complete" ]] || { message 'ERROR: incomplete backup or path outside the lab backups.' >&2; exit 2; }
relative=${backup#"$ROOT/artifacts/"}
[[ "$relative" =~ ^backups/[a-zA-Z0-9_-]+$ ]] || { message 'ERROR: invalid backup directory name.' >&2; exit 2; }
(cd "$backup" && sha256sum -c SHA256SUMS)
source_project=$(cat "$backup/source-project.txt")
if [[ "$mode" == '--clean' ]]; then
  [[ "$LAB_PROJECT" != "$source_project" ]] || { message 'ERROR: clean restore requires a different disposable project.' >&2; exit 2; }
  message 'Creating a clean, independent lab instance.'
  dc down -v --remove-orphans
elif [[ "$mode" == '--in-place' ]]; then
  [[ "$LAB_PROJECT" == "$source_project" ]] || { message 'ERROR: rollback target does not match the snapshot project.' >&2; exit 2; }
else
  message 'ERROR: restore mode must be --clean or --in-place.' >&2
  exit 2
fi
dc up -d --wait db wordpress
wait_files
dc stop wordpress
message 'Replacing only the named lab volume contents, then importing SQL.'
dc run --rm -T --user 0:0 --entrypoint sh cli -c 'test -f /var/www/html/wp-load.php && find /var/www/html -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +'
dc run --rm -T --user 0:0 --entrypoint sh cli -c "tar -xzf '/artifacts/$relative/files.tar.gz' -C /var/www/html && mkdir -p /var/www/html/wp-content/uploads && tar -xzf '/artifacts/$relative/uploads.tar.gz' -C /var/www/html/wp-content/uploads && chown -R 33:33 /var/www/html"
wp --skip-plugins --skip-themes db import "/artifacts/$relative/database.sql"
wp option update home "$URL"
wp option update siteurl "$URL"
wp maintenance-mode deactivate
dc start wordpress
wp eval-file /lab/scripts/php/inventory.php > "$ROOT/artifacts/restored-content-$LAB_PROJECT.json"
cmp "$backup/content.json" "$ROOT/artifacts/restored-content-$LAB_PROJECT.json"
upload_hash > "$ROOT/artifacts/restored-uploads-$LAB_PROJECT.sha256"
cmp "$backup/uploads.sha256" "$ROOT/artifacts/restored-uploads-$LAB_PROJECT.sha256"
bash "$SCRIPT_DIR/quick-check.sh"
message 'Restore verified: post/page counts, content hash, uploads and HTTP checks match.'
