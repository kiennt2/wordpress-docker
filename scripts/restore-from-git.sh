#!/bin/bash

# Restore script for WordPress Docker environment

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*}"
SOURCE_WEB="${ROOT_DIR}/source"
SQL_FILE="wordpress_db.sql"
SQL_SNAPSHOT_FILE="${ROOT_DIR}/snapshot/${SQL_FILE}"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}
source "$ROOT_DIR"/scripts/utils/git-cmd.sh

echo ""
echo "########### Starting WordPress Restore ###########"
# Confirm restoration
echo ""
echo "WARNING: This will replace your current WordPress installation and database!"
# shellcheck disable=SC2162
read -p "Do you want to continue? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Restoration cancelled"
    echo ""
    exit 0
fi
echo ""
source "$ROOT_DIR"/deployment/share/load-env.sh
source "$ROOT_DIR"/scripts/utils/git-config.sh
echo ""
echo "=================================================="
echo "SELECT TAG"
echo "=================================================="
echo ""
echo "Available tags (most recent first):"
echo ""
# TODO: test this against a large number of tags
# Use simple command substitution instead of process substitution
# shellcheck disable=SC2207
TAGS=($(GIT_CMD tag -l --sort=-creatordate | head -n 10))

# Display tags with numbers
for i in "${!TAGS[@]}"; do
  echo "$((i+1)). ${TAGS[$i]}"
done
echo ""

# Prompt user to select a tag by number
# shellcheck disable=SC2162
read -p "Enter tag number (1-${#TAGS[@]}) or press Enter to manually input tag name: " TAG_NUMBER

if [[ "$TAG_NUMBER" =~ ^[0-9]+$ ]] && [ "$TAG_NUMBER" -ge 1 ] && [ "$TAG_NUMBER" -le "${#TAGS[@]}" ]; then
    # User selected a number, use the corresponding tag
    TAG="${TAGS[$((TAG_NUMBER-1))]}"
    echo ""
    echo "Selected tag: $TAG"
else
    # User didn't enter a valid number, ask for exact tag name
    # shellcheck disable=SC2162
    echo ""
    echo "Tag format: snapshot-YYYY-MM-DD"
    # shellcheck disable=SC2162
    read -p "Enter exact tag name: " TAG

    # Verify tag exists
    if ! GIT_CMD rev-parse "$TAG" >/dev/null 2>&1; then
    echo ""
        echo "ERROR: Tag '$TAG' does not exist!"
        exit 1
    fi
    echo ""
    echo "Using tag: $TAG"
fi
echo ""
echo "=================================================="
echo "STOP DOCKER"
echo "=================================================="
echo ""
COMPOSE_NOW down
echo ""
echo "=================================================="
echo "REVERT SOURCE WEB"
echo "=================================================="
echo ""
rm -rf "$SOURCE_WEB"
GIT_CMD reset --hard "$TAG"
echo ""
source "$ROOT_DIR"/scripts/utils/docker-healthy.sh
echo ""
echo "=================================================="
echo "IMPORT DATABASE"
echo "=================================================="
echo ""
cp -f "$SQL_SNAPSHOT_FILE" "$SOURCE_WEB"
COMPOSE_NOW run --rm wordpress-cli db import "$SQL_FILE"
rm "$SOURCE_WEB"/"$SQL_FILE"
echo ""
echo "=================================================="
echo "PUSH CHANGES TO GIT"
echo "=================================================="
echo ""
GIT_CMD push origin "$GIT_MAIN_BRANCH_NAME" -f
echo ""
echo "=================================================="
echo "########### WordPress Restore Complete ###########"
echo "=================================================="
echo ""