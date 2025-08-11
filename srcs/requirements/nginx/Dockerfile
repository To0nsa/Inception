# ./srcs/requirements/nginx/Dockerfile
FROM debian:bullseye-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx \
      curl \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 443
CMD ["nginx","-g","daemon off;"]

