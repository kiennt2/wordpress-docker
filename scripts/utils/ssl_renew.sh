#!/bin/bash

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*/*}"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}
COMPOSE_NOW run certbot renew
COMPOSE_NOW kill -s SIGHUP webserver
docker system prune -af