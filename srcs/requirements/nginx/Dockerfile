# ./srcs/requirements/nginx/Dockerfile
FROM debian:bullseye-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx \
      curl \
 && rm -rf /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443
CMD ["nginx","-g","daemon off;"]

