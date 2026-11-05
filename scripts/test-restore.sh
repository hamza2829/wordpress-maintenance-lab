#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
[[ $# == 1 ]] || { message 'Usage: test-restore.sh BACKUP' >&2; exit 2; }
backup=$(realpath "$1")
source_project=$LAB_PROJECT
wp eval-file /lab/scripts/php/inventory.php > "$ROOT/artifacts/source-before-restore.json"
LAB_PROJECT=wmlrestore LAB_PORT=8081 LAB_DB_PORT=3308 bash "$SCRIPT_DIR/restore.sh" "$backup" --clean
LAB_PROJECT=wmlrestore LAB_PORT=8081 LAB_DB_PORT=3308 bash "$SCRIPT_DIR/checks.sh" restored
wp eval-file /lab/scripts/php/inventory.php > "$ROOT/artifacts/source-after-restore.json"
cmp "$ROOT/artifacts/source-before-restore.json" "$ROOT/artifacts/source-after-restore.json"
docker volume inspect "${source_project}_site" > "$ROOT/artifacts/source-volume.json"
docker volume inspect wmlrestore_site > "$ROOT/artifacts/restore-volume.json"
python3 - "$ROOT" <<'PY'
import json
from pathlib import Path
import sys
root = Path(sys.argv[1]) / 'artifacts'
source = json.loads((root / 'source-volume.json').read_text())[0]['Name']
target = json.loads((root / 'restore-volume.json').read_text())[0]['Name']
assert source != target
before = json.loads((root / 'source-before-restore.json').read_text())
restored = json.loads((root / 'restored-content-wmlrestore.json').read_text())
assert before == restored
(root / 'restore-proof.json').write_text(json.dumps({'clean_instance': True, 'source_volume': source, 'target_volume': target,
    'source': before, 'restored': restored, 'uploads_match': True}, indent=2) + '\n')
PY
cd "$ROOT"
python3 ci/record_case.py restore-clean-content
message 'Clean restore passed: independent volumes, equal post/page counts and content hash, matching uploads, working pages.'
