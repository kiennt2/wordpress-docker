#!/bin/bash

echo ""
echo "########### RUNNING ON LOCAL MACHINE ###########"
echo ""
# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "$SCRIPT_DIR"
ROOT_DIR="${SCRIPT_DIR%/*/*}"
echo "$ROOT_DIR"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}
echo ""
source "$ROOT_DIR"/deployment/share/load-env.sh
echo ""
source "$ROOT_DIR"/deployment/share/nginx-none-ssl.sh
echo ""
echo "=================================================="
echo "UPDATE HOSTS FILE"
echo "=================================================="
echo ""
HOSTS_FILE="/etc/hosts"
LOCAL_IP="127.0.0.1"
# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    echo "sudo command not found. You may need to manually update your hosts file."
    echo ""
    echo "Add the following line to $HOSTS_FILE:"
    echo "$LOCAL_IP $WEB_DOMAIN"
    echo ""
    exit 1
fi
echo "The following entry will be added to your hosts file:"
echo ""
echo "$LOCAL_IP $WEB_DOMAIN"
echo ""
# shellcheck disable=SC2162
read -p "Do you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
echo ""
    echo "Operation cancelled. No changes made to hosts file."
    echo ""
    exit 0
fi
echo ""
# Check for existing entries and add new ones
if grep -q "^$LOCAL_IP\s*$WEB_DOMAIN" "$HOSTS_FILE"; then
    echo "Entry for $WEB_DOMAIN already exists in hosts file."
else
    echo "Adding $WEB_DOMAIN to hosts file..."
    echo "$LOCAL_IP $WEB_DOMAIN" | sudo tee -a "$HOSTS_FILE" > /dev/null
fi

echo ""
echo "Hosts file updated successfully!"
echo ""
echo "Your local environment is now configured with the following domains:"
echo ""
echo "$WEB_DOMAIN"
echo ""
echo "=================================================="
echo "RUN DOCKER"
echo "=================================================="
echo ""
COMPOSE_NOW up -d --build --remove-orphans --force-recreate
echo ""
echo "=================================================="
echo "SETUP COMPLETED"
echo "=================================================="
echo ""

