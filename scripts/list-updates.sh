#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
message 'Available WordPress core updates:'
wp core check-update --format=json
message 'Available plugin updates:'
wp plugin list --update=available --format=json
message 'Available theme updates:'
wp theme list --update=available --format=json
