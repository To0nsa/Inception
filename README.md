# Project README

This document explains how to navigate within the Docker environment, inspect the database, examine WordPress configuration files, and transfer files between host and containers.

---

## Table of Contents

- [Project README](#project-readme)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Managing the Environment](#managing-the-environment)
  - [Directory Structure](#directory-structure)
  - [Working with Containers](#working-with-containers)
    - [Listing Containers](#listing-containers)
    - [Accessing the WordPress Container](#accessing-the-wordpress-container)
    - [Accessing the MariaDB Container](#accessing-the-mariadb-container)
  - [Inspecting the Database](#inspecting-the-database)
  - [Inspecting `wp-config.php`](#inspecting-wp-configphp)
  - [File Transfer Between Host and Container](#file-transfer-between-host-and-container)
    - [Copying from Container to Host](#copying-from-container-to-host)
    - [Copying from Host to Container](#copying-from-host-to-container)
  - [File Transfer Between VM Host and VM](#file-transfer-between-vm-host-and-vm)
    - [Copying from VM host to VM:](#copying-from-vm-host-to-vm)
    - [Copying from VM to VM Host:](#copying-from-vm-to-vm-host)
  - [Managing Volumes](#managing-volumes)
  - [Viewing Logs](#viewing-logs)

---

## Prerequisites

* Docker (version ≥ 20.10)
* Docker Compose (version ≥ 1.29)
* `make` utility (optional, if using the provided Makefile)
* Clone of this repository

1. **Create your `.env` file**

   ```bash
   cp .env.example .env
   ```

   Open `.env` in your editor and fill in all placeholders, for example:

   ```dotenv
   DOMAIN_NAME=example.com
   MYSQL_DATABASE=wp_database
   MYSQL_USER=wp_user

   WP_ADMIN_USER=admin
   WP_ADMIN_EMAIL=admin@example.com

   WP_SECOND_USER=editor
   WP_SECOND_EMAIL=editor@example.com
   ```

2. **Create the `secrets/` directory structure**

   ```bash
   mkdir -p secrets/certs secrets/private
   ```

3. **Generate and Add TLS certificates**

   **Self-signed (for development/testing):**

   ```bash
   openssl req \
     -x509 -nodes -days 365 \
     -newkey rsa:2048 \
     -keyout secrets/private/myKey.key \
     -out secrets/certs/myCert.crt \
     -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=Organization/CN=${DOMAIN_NAME}"
   ```

   This creates a 2048-bit RSA key and a certificate valid for 1 year.

4. **Create password files**

   For each credential, create an empty file under `secrets/` and then open it in your editor to enter the secret value. Do **not** place these in the `.env`.

```bash
# Necessary files for Inception are:
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

---

## Managing the Environment

From the project root on the VM, use the provided Makefile to build, configure docker host directories, and start all services:

```bash
# Build images, create host data dirs, set permissions, and start containers
make up
```

This performs:

1. `mkdir -p /home/$(USER)/data/db /home/$(USER)/data/www`
2. `sudo chown -R $(UID):$(GID) /home/$(USER)/data/db /home/$(USER)/data/www`
3. `docker compose -f srcs/docker-compose.yml up --build`

To stop and remove containers, networks, and anonymous volumes:

```bash
make fclean
```

You can also:

```bash
make build    # Rebuild service images
make restart  # Restart running containers
make logs     # Follow container logs
make prune    # Prune unused Docker resources
make fclean   # Remove containers & host data dirs
make re       # Full rebuild (fclean + up)
make help     # Show all targets
```

Alternatively, invoke Docker Compose directly:

```bash
docker compose -f srcs/docker-compose.yml up --build
docker compose -f srcs/docker-compose.yml down
```

This will build images and start containers for:

* `nginx` (entry point on port 443)
* `wordpress` + `PHP-FPM`
* `mariadb`

---

## Directory Structure

```
.
├── Makefile
├── README.md
├── .gitignore
├── secrets
│   ├── certs
│   │   └── myCert.crt
│   ├── private
│   │   └── myKey.key
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs
    ├── docker-compose.yml
    ├── .env
    ├── .env.example
    └── requirements
        ├── mariadb
        │   ├── conf
        │   │   └── 50-server.cnf
        │   ├── Dockerfile
        │   └── entrypoint.sh
        ├── nginx
        │   ├── conf
        │   │   └── default.conf
        │   └── Dockerfile
        └── wordpress
            ├── Dockerfile
            └── entrypoint.sh

```

* **secrets/**: stores confidential credentials
* **srcs/.env**: environment variables
* **srcs/docker-compose.yml**: service definitions, network and volume mappings

---

## Working with Containers

### Listing Containers

```bash
docker-compose -f srcs/docker-compose.yml ps
```

### Accessing the WordPress Container

```bash
# Open a bash shell inside the wordpress container
docker-compose -f srcs/docker-compose.yml exec wordpress bash

# You will land in /var/www/html by default
pwd  # => /var/www/html
```

### Accessing the MariaDB Container

```bash
# Open a bash shell inside the mariadb container
docker-compose -f srcs/docker-compose.yml exec mariadb bash
```

---

## Inspecting the Database

1. **Enter the container shell**:

   ```bash
   docker-compose -f srcs/docker-compose.yml exec mariadb bash
   ```

2. **Launch the MySQL client**:

   ```bash
   mysql -u"$MYSQL_USER" -p"$(cat /run/secrets/mysql_user_password)" "$MYSQL_DATABASE"
   ```

   * Environment variables are loaded from `/run/secrets` or `.env`.

3. **Common commands**:

   ```sql
   SHOW DATABASES;
   USE $MYSQL_DATABASE;
   SHOW TABLES;
   DESCRIBE wp_options;
   SELECT * FROM wp_users LIMIT 10;
   ```

4. **Exit**:

   ```sql
   EXIT;
   ```

---

## Inspecting `wp-config.php`

1. **Access the WordPress container**:

   ```bash
   docker-compose -f srcs/docker-compose.yml exec wordpress bash
   ```

2. **Locate and view the file**:

   ```bash
   cat /var/www/html/wp-config.php
   ```

3. **Copy to host (optional)**:

   ```bash
   docker cp $(docker-compose -f srcs/docker-compose.yml ps -q wordpress):/var/www/html/wp-config.php ./wp-config.php
   ```

---

## File Transfer Between Host and Container

You can use `docker cp` to move files between your host machine and running containers.

### Copying from Container to Host

```bash
# Syntax:
# docker cp <container>:/path/inside/container /path/on/host

# Example:
docker cp $(docker-compose -f srcs/docker-compose.yml ps -q wordpress):/var/www/html/wp-config.php ~/wp-config.php
```

### Copying from Host to Container

```bash
# Syntax:
# docker cp /path/on/host <container>:/path/inside/container

# Example:
docker cp ~/my-local-plugin.zip $(docker-compose -f srcs/docker-compose.yml ps -q wordpress):/var/www/html/wp-content/plugins/
```

---

## File Transfer Between VM Host and VM

### Copying from VM host to VM:
```bash
scp -P 2222 -r ~/Inception nlouis@localhost:/home/nlouis/
```

### Copying from VM to VM Host:
```bash
scp -P 2222 -r nlouis@localhost:/home/nlouis/Inception ~/Downloads
```

---

## Managing Volumes

* **List volumes**:

  ```bash
  docker volume ls
  ```

* **Inspect a volume**:

  ```bash
  docker volume inspect <volume_name>
  ```

Data is persisted on the host under `/home/<your_login>/data/...` as defined in `docker-compose.yml`.

---

## Viewing Logs

```bash
docker-compose -f srcs/docker-compose.yml logs nginx

docker-compose -f srcs/docker-compose.yml logs wordpress

docker-compose -f srcs/docker-compose.yml logs mariadb
```

Add the `-f` flag to follow logs in real time:

```bash
docker-compose -f srcs/docker-compose.yml logs -f wordpress
```

---

docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
