#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
wp eval-file /lab/scripts/php/versions.php > "$ROOT/artifacts/rollback-before-versions.json"
wp eval-file /lab/scripts/php/inventory.php > "$ROOT/artifacts/rollback-before-content.json"
set +e
LAB_INJECT_FAILURE=1 bash "$SCRIPT_DIR/update.sh" 2>&1 | tee "$ROOT/artifacts/rollback-update.log"
result=${PIPESTATUS[0]}
set -e
[[ "$result" == 20 ]] || { message "ERROR: expected rollback code 20, got $result." >&2; exit 1; }
wp eval-file /lab/scripts/php/versions.php > "$ROOT/artifacts/rollback-after-versions.json"
wp eval-file /lab/scripts/php/inventory.php > "$ROOT/artifacts/rollback-after-content.json"
cmp "$ROOT/artifacts/rollback-before-versions.json" "$ROOT/artifacts/rollback-after-versions.json"
cmp "$ROOT/artifacts/rollback-before-content.json" "$ROOT/artifacts/rollback-after-content.json"
cd "$ROOT"
python3 ci/record_case.py update-rollback
message 'Expected failed update returned 20; versions, content and browser checks are restored.'
