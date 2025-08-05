#!/bin/bash
set -e

DATADIR=/var/lib/mysql
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_ROOT_PW="$(cat /run/secrets/mysql_root_password)"
MYSQL_USER_PW="$(cat /run/secrets/mysql_user_password)"

# If this is the very first run, bootstrap the data directory
if [ ! -d "${DATADIR}/mysql" ]; then
  echo "🔧 Bootstrapping MariaDB data directory…"
  mariadb-install-db --user=mysql --datadir="${DATADIR}"

  # Generate init SQL that runs exactly once
  cat > /tmp/init.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PW}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER    IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PW}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

  echo "✅ init.sql created; now starting MariaDB with init-file…"
  exec mysqld \
    --datadir="${DATADIR}" \
    --init-file=/tmp/init.sql
fi

# For all subsequent runs, just start MariaDB normally
echo "🔗 Starting MariaDB…"
exec mysqld --datadir="${DATADIR}"
