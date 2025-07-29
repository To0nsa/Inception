# ./srcs/requirements/wordpress/Dockerfile

# Base image: Debian Bullseye slim (the penultimate stable release)
FROM debian:bullseye-slim

# Install PHP-FPM and necessary extensions/tools without extra recommends to keep the image small
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      php-fpm \
      php-mysql \
      php-xml \
      php-mbstring \
      php-gd \
      php-curl \
      php-cli \
      curl \
      tar && \
    rm -rf /var/lib/apt/lists/*

# Prepare the webroot directory and give ownership to the www-data user
RUN mkdir -p /var/www/html && \
    chown www-data:www-data /var/www/html

# Create and set ownership for the PHP-FPM runtime directory
RUN mkdir -p /run/php && \
    chown www-data:www-data /run/php
                                # Directory for PHP-FPM PID and socket files

# Configure PHP-FPM to listen on all interfaces TCP port 9000 instead of a Unix socket
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' \
    /etc/php/*/fpm/pool.d/www.conf

# install WP-CLI into /usr/local/bin/wp
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Copy our entrypoint script into the image
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the FastCGI port (no host mapping here, Nginx will connect internally)
EXPOSE 9000

# Use our entrypoint script as PID 1, which bootstraps WordPress if needed
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command: start PHP-FPM in the foreground for Docker management
CMD ["php-fpm7.4", "-F"]
