# Makefile for Inception Docker stack

# Path to the Docker Compose file
COMPOSE := docker compose -f srcs/docker-compose.yml

.PHONY: all up down build restart logs fclean re help

all: up

## Build images and start containers in detached mode
up:
	@mkdir -p /home/$(USER)/data/db /home/$(USER)/data/www
	@sudo chown -R $(UID):$(GID) /home/$(USER)/data/db /home/$(USER)/data/www
	$(COMPOSE) up -d --build

## Stop and remove containers, networks
down:
	$(COMPOSE) down

## (Re)build all service images
build:
	$(COMPOSE) build

## Restart running containers
restart:
	$(COMPOSE) restart

## Tail logs for all services
logs:
	$(COMPOSE) logs -f

## Prune unused Docker resources
prune:
	docker system prune -af --volumes

## Remove containers and wipe host data directories
fclean: down
	sudo rm -rf /home/$(USER)/data/db /home/$(USER)/data/www

## Full rebuild: clean then bring everything up
re: fclean all

## Display available targets
help:
	@echo "Available commands:"
	@echo "  make all       (default) build & start everything"
	@echo "  make up        Build images and start containers"
	@echo "  make down      Stop & remove containers"
	@echo "  make build     Rebuild service images"
	@echo "  make restart   Restart running containers"
	@echo "  make logs      Follow container logs"
	@echo "  make prune     Remove unused Docker resources"
	@echo "  make fclean    Remove containers & host data dirs"
	@echo "  make re        Clean and rebuild from scratch"
	@echo "  make help      Show this help message"
