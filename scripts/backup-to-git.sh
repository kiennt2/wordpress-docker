#!/bin/bash

# Backup script for WordPress Docker environment

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*}"
BACKUP_DIR="${ROOT_DIR}/snapshot"
SQL_FILE_NAME="wordpress_db.sql"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}

echo ""
echo "########### Starting WordPress Backup ###########"
echo ""
echo "Project directory: $ROOT_DIR"
echo ""
source "$ROOT_DIR"/scripts/utils/docker-healthy.sh
echo ""
source "$ROOT_DIR"/scripts/utils/dump-db-via-cli.sh
echo ""
echo "=================================================="
echo "NAVIGATE TO PROJECT DIRECTORY"
echo "=================================================="
echo ""
echo "$ROOT_DIR"
# shellcheck disable=SC2164
cd "$ROOT_DIR"
echo ""
source "$ROOT_DIR"/deployment/share/load-env.sh
source "$ROOT_DIR"/scripts/utils/git-config.sh
echo ""
echo "=================================================="
echo "PUSH DATA TO GIT REPOSITORY & CREATE TAG"
echo "=================================================="
echo ""
echo ">>> ADDING SQL FILE TO GIT"
git add "./snapshot"
echo ""
echo ">>> ADDING SOURCE FILE TO GIT"
git add "./source"
echo ""
echo ">>> COMMITTING CHANGES TO GIT REPOSITORY"
echo ""
git commit -m "Snapshot: $(date '+%Y-%m-%d %H:%M:%S') - Backup of WordPress database and source files"
echo ""
echo ">>> PUSHING CHANGES TO GIT"
echo ""
git push
echo ""
echo ">>> TAGGING"
echo ""
# shellcheck disable=SC2034
TAG_NAME=snapshot-"$(date '+%Y-%m-%d')"
# Check if tag exists locally
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "Tag $TAG_NAME exists locally. Deleting local tag..."
  echo ""
  git tag -d "$TAG_NAME"
  # Check if tag exists remotely before trying to delete it
  if git ls-remote --tags origin "refs/tags/$TAG_NAME" | grep -q "$TAG_NAME"; then
    echo "Tag $TAG_NAME exists remotely. Deleting remote tag..."
    echo ""
    git push origin --delete "$TAG_NAME"
  else
    echo "Remote tag $TAG_NAME doesn't exist, skipping remote deletion."
    echo ""
  fi
fi
# Create and push new tag
git tag -a "$TAG_NAME" -m "Backup of WordPress database and source files"
echo ""
echo ">>> PUSHING TAG NAME"
echo ""
git push origin "$TAG_NAME"
echo ""
echo "=================================================="
echo "BACKUP SUCCESSFULLY !!!"
echo "=================================================="
echo ""
echo "Database dump: $BACKUP_DIR/wordpress_db.sql"
echo ""
echo "Git Tag: $TAG_NAME"
echo ""
echo "=================================================="
echo ""