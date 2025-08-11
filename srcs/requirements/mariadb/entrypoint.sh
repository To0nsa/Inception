#!/bin/sh
set -e

DATADIR=/var/lib/mysql
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_ROOT_PW="$(cat /run/secrets/mysql_root_password)"
MYSQL_USER_PW="$(cat /run/secrets/mysql_user_password)"
MARKER="${DATADIR}/.bootstrapped"

# First boot: initialize datadir
if [ ! -d "${DATADIR}/mysql" ]; then
  echo "🔧 Bootstrapping MariaDB data directory…"
  mariadb-install-db --user=mysql --datadir="${DATADIR}"
fi

# Only do bootstrap SQL once
if [ ! -f "$MARKER" ]; then
  echo "🚀 Starting mysqld (background) to run bootstrap SQL…"
  mysqld --datadir="${DATADIR}" --skip-networking --socket=/tmp/mysql.sock &
  MYPID=$!

  # Try ping without pw first (fresh install), then with pw (restarts)
  if ! mysqladmin --protocol=SOCKET --socket=/tmp/mysql.sock \
        --user=root --silent --connect-timeout=1 --wait=60 ping >/dev/null 2>&1; then
    mysqladmin --protocol=SOCKET --socket=/tmp/mysql.sock \
        --user=root --password="${MYSQL_ROOT_PW}" \
        --silent --connect-timeout=60 --wait=60 ping >/dev/null
  fi

  # Run bootstrap SQL (safe even if rerun, but guarded by marker anyway)
  mysql --protocol=SOCKET --socket=/tmp/mysql.sock -uroot -p"${MYSQL_ROOT_PW}" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PW}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PW}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  # Stop background mysqld gracefully
  mysqladmin --protocol=SOCKET --socket=/tmp/mysql.sock \
    -uroot -p"${MYSQL_ROOT_PW}" shutdown

  touch "$MARKER"
fi

echo "🔗 Starting MariaDB (foreground)…"
exec mysqld --datadir="${DATADIR}" --bind-address=0.0.0.0
