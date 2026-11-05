#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
phase=${1:-manual}
[[ "$phase" =~ ^[a-z0-9_-]+$ ]] || { message 'ERROR: invalid test phase.' >&2; exit 2; }
bash "$SCRIPT_DIR/quick-check.sh"
message "Running Playwright checks: $phase."
cd "$ROOT"
BASE_URL="$URL" TEST_PHASE="$phase" npx playwright test
bash "$SCRIPT_DIR/quick-check.sh"
