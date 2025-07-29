# Use Debian Bullseye (the penultimate stable release) as a minimal base image
FROM debian:bullseye-slim

# 1. Install MariaDB server without extra recommends to keep image small,
#    then clean up apt caches to reduce layer size
RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server \
 && rm -rf /var/lib/apt/lists/*

# 2. Overlay our custom MariaDB configuration so it binds on 0.0.0.0, runs as root, etc.
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# 3. Ensure the runtime directory for the socket and PID file exists and is owned by the mysql user
RUN mkdir -p /run/mysqld \
 && chown mysql:mysql /run/mysqld

# 4. Add our initialization script (entrypoint) into the image and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 5. Declare that /var/lib/mysql is a data volume so Docker preserves it across container lifecycles
VOLUME ["/var/lib/mysql"]

# 6. Expose the default MariaDB port to allow connections from linked services
EXPOSE 3306

# 7. Use our custom entrypoint script as PID 1; it bootstraps the database on first run
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# 8. Default command: start the MariaDB daemon in safe mode
CMD ["mysqld_safe"]
