# ./srcs/requirements/mariadb/Dockerfile
FROM debian:bullseye-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server \
 && rm -rf /var/lib/apt/lists/*

# Overlay our custom MariaDB configuration so it binds on 0.0.0.0, runs as root, etc.
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Ensure the runtime directory for the socket and PID file exists and is owned by the mysql user
RUN mkdir -p /run/mysqld \
 && chown mysql:mysql /run/mysqld

# Add our initialization script (entrypoint) into the image and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Declare that /var/lib/mysql is a data volume so Docker preserves it across container lifecycles
VOLUME ["/var/lib/mysql"]

# Expose the default MariaDB port to allow connections from linked services
EXPOSE 3306

# Use our custom entrypoint script as PID 1; it bootstraps the database on first run
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
