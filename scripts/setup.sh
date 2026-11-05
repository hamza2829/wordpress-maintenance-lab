#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
trap 'message "ERROR: setup failed at line $LINENO." >&2' ERR
message 'Starting the disposable database and WordPress.'
dc up -d --wait db wordpress
wait_files
if wp core is-installed >/dev/null 2>&1; then
  message 'Site is already installed. Existing content is retained.'
  bash "$SCRIPT_DIR/quick-check.sh"
  exit 0
fi
message "Installing intentional old core $CORE_OLD for the update demonstration."
wp core download --version="$CORE_OLD" --locale=en_US --force --skip-content
wp core install --url="$URL" --title='Nordlicht Reparaturatelier' --admin_user="$LAB_ADMIN" --admin_password="$LAB_PASSWORD" --admin_email="$LAB_EMAIL" --skip-email
wp plugin delete --all
wp theme install "$PARENT_THEME"
wp plugin install hello-dolly --version="$PLUGIN_OLD"
dc run --rm -T --user 0:0 --entrypoint sh cli -c 'cp -R /lab/site/themes/nordlicht-child /var/www/html/wp-content/themes/ && cp -R /lab/site/plugins/nordlicht-lab /var/www/html/wp-content/plugins/ && chown -R 33:33 /var/www/html/wp-content'
wp plugin activate nordlicht-lab
wp theme activate nordlicht-child
wp language core install de_DE --activate
wp eval-file /lab/scripts/php/seed.php
wp rewrite structure '/%postname%/'
wp rewrite flush
dc run --rm -T --user 0:0 --entrypoint sh cli -c 'cp /lab/site/apache.htaccess /var/www/html/.htaccess && chown 33:33 /var/www/html/.htaccess'
dc restart wordpress
bash "$SCRIPT_DIR/quick-check.sh"
wp eval-file /lab/scripts/php/versions.php > "$ROOT/artifacts/versions-before.json"
message 'Setup complete. All pages, posts, settings and uploads are synthetic.'
