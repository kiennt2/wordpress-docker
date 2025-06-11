#!/bin/bash

# Backup script for WordPress Docker environment
# Created on: $(date '+%Y-%m-%d')

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*}"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}

# Create backup directory with timestamp
BACKUP_DIR="${ROOT_DIR}/backups/$(date '+%Y-%m-%d_%H-%M-%S')"
mkdir -p "$BACKUP_DIR"

echo ""
echo "########### Starting WordPress Backup ###########"
echo ""
echo "=================================================="
echo "NAVIGATE TO PROJECT DIRECTORY"
echo "=================================================="
echo ""
echo "$ROOT_DIR"
# shellcheck disable=SC2164
cd "$ROOT_DIR"
echo ""
source "$ROOT_DIR"/scripts/utils/docker-healthy.sh
echo ""
source "$ROOT_DIR"/scripts/utils/dump-db-via-cli.sh
echo ""
echo "=================================================="
echo "CREATE SOURCE FILES BACKUP"
echo "=================================================="
# Create a zip archive of WordPress source files
echo ""
echo "Zipping source files, please wait ..."
zip -r -q wordpress_files.zip "./source" -x "*node_modules/*" -x "*.git*" -x "*.DS_Store"
echo ""
# shellcheck disable=SC2181
# shellcheck disable=SC2320
if [ $? -eq 0 ]; then
  echo "✓ Source files backup completed"
  mv -f wordpress_files.zip "$BACKUP_DIR"
else
  echo "✗ Source files backup failed"
fi
echo ""
echo "=================================================="
echo "CLEANING UP OLD BACKUPS"
echo "=================================================="
echo ""
MAX_BACKUPS=14
# Count how many backup directories we have
BACKUP_COUNT=$(find "${ROOT_DIR}/backups" -maxdepth 1 -type d -not -path "${ROOT_DIR}/backups" | wc -l)
# If we have more than MAX_BACKUPS, remove the oldest ones
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
  # Calculate how many to remove
  REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
  echo "Found $BACKUP_COUNT backups, removing oldest $REMOVE_COUNT..."
  echo ""
  # List all backup directories sorted by name (which includes timestamp - oldest first)
  find "${ROOT_DIR}/backups" -maxdepth 1 -type d -not -path "${ROOT_DIR}/backups" | \
  sort | \
  head -n "$REMOVE_COUNT" | \
  while read -r dir; do
    echo "Removing: $dir"
    echo ""
    rm -rf "$dir"
  done

  echo "✓ Removed $REMOVE_COUNT old backups"
else
  echo "✓ No cleanup needed ( found $BACKUP_COUNT backups, threshold is $MAX_BACKUPS )"
fi
echo ""
echo "=================================================="
echo "BACKUP SUCCESSFULLY !!!"
echo "=================================================="
echo ""
echo "Database dump: $BACKUP_DIR/wordpress_db.sql"
echo ""
echo "Source files: $BACKUP_DIR/wordpress_files.zip"
echo ""
echo "=================================================="
echo ""