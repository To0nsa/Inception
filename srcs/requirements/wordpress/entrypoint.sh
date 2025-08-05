#!/bin/bash
set -e

# 0) Variables & secrets
WP_PATH=/var/www/html

DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"
DB_NAME="${WORDPRESS_DB_NAME}"
DB_USER="${WORDPRESS_DB_USER}"
DB_PASSWORD="$(cat /run/secrets/mysql_user_password)"

DOMAIN_NAME="${DOMAIN_NAME}"
WP_TITLE="${WP_TITLE:-Inception Blog}"

WP_ADMIN_USER="${WP_ADMIN_USER}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL}"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"

WP_SECOND_USER="${WP_SECOND_USER}"
WP_SECOND_EMAIL="${WP_SECOND_EMAIL}"
WP_SECOND_PASSWORD="$(cat /run/secrets/wp_user_password)"

WP_CLI="runuser -u www-data -- wp --allow-root --path=${WP_PATH}"

echo "DB_USER=$DB_USER"
echo "DB_NAME=$DB_NAME"
echo "MYSQL_USER_PW=$(cat /run/secrets/mysql_user_password)"

# 1) Prep file permissions
mkdir -p "${WP_PATH}" /var/www/.wp-cli/cache
chown -R www-data:www-data "${WP_PATH}" /var/www/.wp-cli

# 2) Download core if missing
if [ ! -d "${WP_PATH}/wp-admin" ]; then
  echo "⏳ Downloading WordPress core..."
  ${WP_CLI} core download
  echo "✅ WordPress core downloaded."
else
  echo "WordPress is present."
fi

cd "${WP_PATH}"

# 3) Generate wp-config.php if needed
if [ ! -f wp-config.php ] || ! grep -q "DB_NAME" wp-config.php; then
  echo "🔧 Generating wp-config.php…"
  ${WP_CLI} config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="${DB_HOST}" \
    --dbcharset="utf8mb4" \
    --dbcollate="" \
    --skip-check \
    --skip-salts \
    --force

  # re-write those constants so they’re properly quoted
  ${WP_CLI} config set DB_HOST    "${DB_HOST}"
  ${WP_CLI} config set DB_CHARSET "utf8mb4"
  ${WP_CLI} config set DB_COLLATE ""

  ${WP_CLI} config shuffle-salts
  echo "✅ wp-config.php created."
else
  echo "wp-config.php is already set."
fi

# 4) Wait for MariaDB to be listening
echo "⏳ Waiting for database …"
# busy-wait until WP-CLI’s own db check succeeds
until ${WP_CLI} db check > /dev/null 2>&1; do
  :  # no-op
done
echo "✅ Database is up!"

# 5) Install WP core if not yet installed
if ! ${WP_CLI} core is-installed --quiet; then
  echo "⚙️ Installing WordPress core…"
  ${WP_CLI} core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email
  echo "✅ WordPress core installed."
else
  echo "WordPress core is installed."
fi

# 6) Create users via WP-CLI
echo "🔧 Ensuring admin and second user exist…"

if ${WP_CLI} user exists "${WP_ADMIN_USER}" --quiet; then
  echo "Admin user '${WP_ADMIN_USER}' exists."
else
  ${WP_CLI} user create \
    "${WP_ADMIN_USER}" "${WP_ADMIN_EMAIL}" \
    --role=administrator \
    --user_pass="${WP_ADMIN_PASSWORD}" \
  && echo "Created admin user '${WP_ADMIN_USER}'."
fi

if ${WP_CLI} user exists "${WP_SECOND_USER}" --quiet; then
  echo "Author user '${WP_SECOND_USER}' exists."
else
  ${WP_CLI} user create \
    "${WP_SECOND_USER}" "${WP_SECOND_EMAIL}" \
    --role=author \
    --user_pass="${WP_SECOND_PASSWORD}" \
  && echo "Created author user '${WP_SECOND_USER}'."
fi

echo "✅ WordPress is all set"

# 7) Hand off to PHP-FPM
exec "$@"
