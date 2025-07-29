#!/bin/sh
set -e  # Exit immediately if any command fails to prevent partial bootstrapping

# Directory where WordPress files should reside inside the container
WEBROOT=/var/www/html

# Paths where Docker mounts secrets
WP_ADMIN_PASSWORD_FILE=/run/secrets/wp_admin_password
WP_SECOND_PASSWORD_FILE=/run/secrets/wp_user_password

# Read the secrets into shell variables
# (the files are mounted read-only by Docker)
WP_ADMIN_PASSWORD="$(cat "$WP_ADMIN_PASSWORD_FILE")"
WP_SECOND_PASSWORD="$(cat "$WP_SECOND_PASSWORD_FILE")"

# 1. If the webroot is empty (first container start or fresh bind mount), bootstrap WordPress
if [ -z "$(ls -A "$WEBROOT")" ]; then
  echo "Populating $WEBROOT with WordPress..."
  # 1.a Download the latest WordPress archive silently
  # 1.b Pipe it directly into tar to extract into the webroot
  curl -fsSL https://wordpress.org/latest.tar.gz \
    | tar -xz -C "$WEBROOT" --strip-components=1
  # 1.c Ensure proper file ownership so PHP-FPM (www-data) can read/write
  chown -R www-data:www-data "$WEBROOT"
  echo "WordPress installed."
fi

cd /var/www/html

# 2. Perform install & user creation if wp-config.php is not yet present
if [ ! -f wp-config.php ]; then
  echo "Installing WordPress core and users via WP-CLI…"

  # Generate wp-config.php using DB creds from env (or other secrets)
  wp config create \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$(cat /run/secrets/mysql_password)" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --skip-check

  # Core install with the administrator account
  wp core install \
    --url="https://$DOMAIN_NAME" \
    --title="Inception Site" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email

  # Create the second user
  wp user create "$WP_SECOND_USER" "$WP_SECOND_EMAIL" \
    --role=author \
    --user_pass="$WP_SECOND_PASSWORD"

  echo "WordPress installed with two users."
fi

# 2. Exec the container's CMD (php-fpm) replacing this shell process
#    This ensures PHP-FPM runs as PID 1 to handle signals correctly
exec "$@"
