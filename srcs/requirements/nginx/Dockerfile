# ./srcs/requirements/nginx/Dockerfile
FROM debian:bullseye-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx \
      curl \
 && rm -rf /var/lib/apt/lists/*

# Run a shell that echoes first, then starts NGINX in the foreground
ENTRYPOINT ["/bin/sh", "-c", "echo '🟢 NGINX is running'; exec nginx -g 'daemon off;'"]

