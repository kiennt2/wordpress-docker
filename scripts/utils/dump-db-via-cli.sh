#!/bin/bash

echo "=================================================="
echo "DUMPING DATABASE"
echo "=================================================="
echo ""
# Create temporary directory with proper permissions for database dump
TEMP_DB_DIR="${ROOT_DIR}/temp_backup"
mkdir -p "$TEMP_DB_DIR"
chmod 777 "$TEMP_DB_DIR"
# Export using a temp directory with proper permissions
COMPOSE_NOW run --rm -v "$TEMP_DB_DIR:/tmp/backup" wordpress-cli db export /tmp/backup/wordpress_db.sql --add-drop-table
# Move the dump file to the backup directory
mv -f "$TEMP_DB_DIR/wordpress_db.sql" "$BACKUP_DIR"
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  echo "✓ Database dump completed"
else
  echo "✗ Database dump failed"
fi
# Clean up temp directory
rm -rf "$TEMP_DB_DIR"