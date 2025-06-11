#!/bin/bash

# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*/*}"

# Display strong warning message
echo "****************************************************************************"
echo "*                            ⚠️  WARNING ⚠️                                *"
echo "*                                                                          *"
echo "* THIS SCRIPT WILL PERFORM THE FOLLOWING DESTRUCTIVE OPERATIONS:           *"
echo "* - Stop all Docker containers                                             *"
echo "* - DELETE all data, backups, and source directories                       *"
echo "* - Reset the Git repository to HEAD                                       *"
echo "* - Remove configuration files                                             *"
echo "* - DELETE ALL TAGS (both locally and remotely)                            *"
echo "*                                                                          *"
echo "****************************************************************************"
echo ""

# Ask for confirmation
# shellcheck disable=SC2162
read -p "Are you ABSOLUTELY SURE you want to continue? (y/N) " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

source "$ROOT_DIR"/deployment/share/load-env.sh
source "$ROOT_DIR"/scripts/utils/git-cmd.sh
touch2() { mkdir -p "$(dirname "$1")" && touch "$1" ;}
echo ""
echo ">>> STOP DOCKER"
echo ""
docker compose -f "$ROOT_DIR"/docker-compose.yml down
echo ""
echo ">>> REMOVE DIRs"
echo ""
sudo rm -rf "$ROOT_DIR"/backups
sudo rm -rf "$ROOT_DIR"/snapshot
sudo rm -rf "$ROOT_DIR"/source
sudo rm -rf "$ROOT_DIR"/data
sudo rm "$ROOT_DIR"/nginx-conf/nginx.conf
sudo rm "$ROOT_DIR"/.env
echo ""
echo ">>> CREATE EMPTY DIRs"
echo ""
touch2 "$ROOT_DIR"/backups/.gitkeep
touch2 "$ROOT_DIR"/snapshot/.gitkeep
touch2 "$ROOT_DIR"/source/.gitkeep
touch2 "$ROOT_DIR"/data/certbot/.gitkeep
touch2 "$ROOT_DIR"/data/mysql/.gitkeep
touch2 "$ROOT_DIR"/data/redis/.gitkeep
echo ""
echo ">>> PUSH TO GIT"
echo ""
GIT_CMD add -A
GIT_CMD commit -m '"Reset all: removing data, backups, source, and configuration files"'
GIT_CMD push origin "$GIT_MAIN_BRANCH_NAME" -f
# Get current repository remote name (default to 'origin')
REMOTE=$(GIT_CMD remote | head -n 1)
if [ -z "$REMOTE" ]; then
  REMOTE="origin"
fi
# First fetch all tags from remote to ensure we have them all locally
GIT_CMD fetch --tags
# Save all tags to a variable before we start deleting
ALL_TAGS=$(GIT_CMD tag)

# Check if there are any tags to delete
if [ -n "$ALL_TAGS" ]; then
  echo "The following tags will be deleted (both locally and remotely):"
  echo "$ALL_TAGS"

  # shellcheck disable=SC2162
  read -p "Proceed with tag deletion? (y/N) " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Tag deletion skipped."
  else
    # Delete all local tags
    for TAG in $ALL_TAGS; do
      GIT_CMD tag -d "$TAG"
    done
    # Delete all remote tags using the saved list
    for TAG in $ALL_TAGS; do
      GIT_CMD push "$REMOTE" :refs/tags/"$TAG"
    done
    echo "All tags have been deleted successfully."
  fi
else
  echo "No tags found to delete."
fi
echo ""
echo ""
echo ""
echo ">>> RESET OPERATION COMPLETED."
echo ""
echo "***************************************************************************************************"
echo "                                   ⚠️  Recovery Options ⚠️"
echo ""
echo "1. If you have external backups (outside the deleted directories), you can restore from them"
echo "2. If you need to recover to a previous state, you can use Git to restore from a specific commit:"
echo "   git log --oneline          # View commit history"
echo "   git checkout <commit-hash> # Go to specific commit"
echo "3. If your remote repository contains commits that weren't overwritten by the force push,"
echo "   you may be able to recover by fetching from remote"
echo ""
echo "***************************************************************************************************"
echo ""
