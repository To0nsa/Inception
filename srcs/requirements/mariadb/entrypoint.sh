#!/bin/sh
set -e  # Exit immediately if any command exits with a non-zero status

# Directory where MariaDB stores its data files
DATADIR=/var/lib/mysql

# On first run, the mysql system tables won’t exist yet
# If the data directory already exists, skip initialization
if [ ! -d "$DATADIR/mysql" ]; then
  echo "Initializing MariaDB at $DATADIR…"
  # Bootstrap the system tables as the mysql user into our data directory
  mariadb-install-db --user=mysql --datadir="$DATADIR"
  
  # Create a temporary SQL script to:
  # 1) Secure the root account (set password & allow remote root login)
  # 2) Create the WordPress database and application user with proper grants
  cat <<EOF > /tmp/mysql-init.sql
-- Set root password and allow remote root login
ALTER USER 'root'@'localhost' IDENTIFIED BY "${MYSQL_ROOT_PASSWORD:=$(cat /run/secrets/mysql_root_password)}";
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY "${MYSQL_PASSWORD:=$(cat /run/secrets/mysql_password)}";
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Create your WordPress database & user
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER    IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY "${MYSQL_PASSWORD:=$(cat /run/secrets/mysql_password)}";
GRANT ALL ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

  echo "Running initial SQL…"
  # Start MariaDB in safe mode, pointing at our data directory and running the init SQL
  exec mysqld_safe --datadir="$DATADIR" --init-file=/tmp/mysql-init.sql
fi

echo "Starting MariaDB…"
# Use exec to replace this script with the real server process, passing any arguments
exec "$@" --datadir="$DATADIR"
