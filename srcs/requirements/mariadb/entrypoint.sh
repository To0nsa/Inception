#!/bin/bash
set -e

DATADIR=/var/lib/mysql
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_ROOT_PW="$(cat /run/secrets/mysql_root_password)"
MYSQL_USER_PW="$(cat /run/secrets/mysql_user_password)"

if [ ! -d "${DATADIR}/mysql" ]; then
  echo "🔧 Bootstrapping MariaDB data directory…"
  mariadb-install-db --user=mysql --datadir="${DATADIR}"
fi

echo "🐢 Starting MariaDB (background) for user check…"
mysqld --datadir="${DATADIR}" --skip-networking --socket=/tmp/mysql.sock &
MYPID=$!

for i in {30..0}; do
  mysqladmin ping --socket=/tmp/mysql.sock -uroot -p"${MYSQL_ROOT_PW}" &>/dev/null && break
  echo "  waiting for mysqld… ($i)"
  sleep 1
done

EXISTS=$(mysql --socket=/tmp/mysql.sock -uroot -p"${MYSQL_ROOT_PW}" \
  -se "SELECT COUNT(*) FROM mysql.user WHERE user='${MYSQL_USER}' AND host='%'")

if [ "$EXISTS" -eq 0 ]; then
  echo "👤 User '${MYSQL_USER}'@'%' not found. Creating DB & user…"
  mysql --socket=/tmp/mysql.sock -uroot -p"${MYSQL_ROOT_PW}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PW}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PW}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
else
  echo "✅ User '${MYSQL_USER}'@'%' already exists. Skipping init."
fi

echo "🛑 Stopping background MariaDB (PID $MYPID)…"
mysqladmin --socket=/tmp/mysql.sock -uroot -p"${MYSQL_ROOT_PW}" shutdown

echo "🔗 Starting MariaDB (foreground)…"
exec mysqld --datadir="${DATADIR}"
