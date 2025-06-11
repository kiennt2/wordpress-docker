#!/bin/bash

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
docker compose -f "$SCRIPT_DIR"/docker-compose.yml run --rm wordpress-cli "$@"
