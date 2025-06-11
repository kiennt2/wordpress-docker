#!/bin/bash

# Restore script for WordPress Docker environment

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*}"
BACKUP_DIR="${ROOT_DIR}/backups"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}

echo ""
echo "########### Starting WordPress Restore ###########"
echo ""
# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi
echo ""
echo "=================================================="
echo "AVAILABLE BACKUPS"
echo "=================================================="
echo ""
backups=()
i=1
for backup in "$BACKUP_DIR"/*; do
    if [ -d "$backup" ]; then
        backups+=("$(basename "$backup")")
        echo "$i) $(basename "$backup")"
        ((i++))
    fi
done

if [ ${#backups[@]} -eq 0 ]; then
    echo "Error: No backups found in $BACKUP_DIR"
    exit 1
fi
echo ""
# Ask user to select a backup
# shellcheck disable=SC2162
read -p "Select backup to restore (1-${#backups[@]}): " selection
echo ""
# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
    echo "Error: Invalid selection. Please enter a number between 1 and ${#backups[@]}"
    echo ""
    exit 1
fi

# Get selected backup
selected_backup="${backups[$((selection-1))]}"
backup_path="$BACKUP_DIR/$selected_backup"

echo "You selected: $selected_backup"
echo "Backup path: $backup_path"

# Check if backup contains necessary files
db_dump=$(find "$backup_path" -name "*.sql" | head -n 1)
zip_file=$(find "$backup_path" -name "*.zip" | head -n 1)

if [ -z "$db_dump" ]; then
    echo "Error: No database dump (*.sql) found in the selected backup"
    echo ""
    exit 1
fi

if [ -z "$zip_file" ]; then
    echo "Error: No zip file (*.zip) found in the selected backup"
    echo ""
    exit 1
fi

# Confirm restoration
echo ""
echo "WARNING: This will replace your current WordPress installation and database!"
# shellcheck disable=SC2162
read -p "Do you want to continue? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Restoration cancelled"
    echo ""
    exit 0
fi
echo ""
source "$ROOT_DIR"/scripts/utils/docker-healthy.sh
echo ""
echo "=================================================="
echo "IMPORT DATABASE"
echo "=================================================="
# Copy database to source folder then import it via wordpress cli container, remove database file afterwards
cp -f "$db_dump" "$ROOT_DIR"/source/
# shellcheck disable=SC2164
COMPOSE_NOW run --rm wordpress-cli db import wordpress_db.sql
rm "$ROOT_DIR"/source/wordpress_db.sql
echo ""
echo "=================================================="
echo "STOP DOCKER"
echo "=================================================="
echo ""
COMPOSE_NOW down
echo ""
echo "=================================================="
echo "DELETE SOURCE FOLDER"
echo "=================================================="
echo ""
echo "$ROOT_DIR"/source
rm -rf "$ROOT_DIR"/source
echo ""
echo "=================================================="
echo "UNZIP BACKUP FILE"
echo "=================================================="
echo ""
echo "$zip_file"
echo ""
echo ">>>"
echo ""
echo "$ROOT_DIR"
unzip -q "$zip_file" -d "$ROOT_DIR"
echo ""
echo "=================================================="
echo "START DOCKER"
echo "=================================================="
echo ""
COMPOSE_NOW up -d
echo ""
echo "=================================================="
echo "########### WordPress Restore Complete ###########"
echo "=================================================="
echo ""