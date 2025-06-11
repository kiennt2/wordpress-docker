#!/bin/bash

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck disable=SC2145
# shellcheck disable=SC2068
# shellcheck disable=SC2027
docker compose -f "$SCRIPT_DIR"/docker-compose.yml exec wordpress bash -c 'cd /var/www/html && composer "$@"' -- "$@"
