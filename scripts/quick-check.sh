#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
temporary=$(mktemp)
trap 'rm -f -- "$temporary"' EXIT
curl --fail --silent --show-error --retry 15 --retry-all-errors --retry-delay 1 "$URL/" > "$temporary"
grep -q 'Nordlicht' "$temporary"
if grep -Eiq 'Fatal error|Parse error|Warning:|Notice:' "$temporary"; then
  message 'ERROR: PHP error text in the response.' >&2
  exit 1
fi
dc exec -T wordpress sh -c 'if test -f wp-content/debug.log && grep -E "PHP (Fatal error|Parse error|Warning|Notice|Deprecated)" wp-content/debug.log; then exit 1; fi'
message 'HTTP marker and PHP log checks passed.'
