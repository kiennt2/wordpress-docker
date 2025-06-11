#!/bin/bash

echo ""
echo "################ RUNNING ON CLOUD ################"
echo ""
echo "=================================================="
echo "DNS CONFIGURATION CHECK"
echo "=================================================="
echo ""
echo "IMPORTANT: Before proceeding, ensure you have configured your DNS records."
echo "You must point an A record from your domain to this server's IP address."
echo "This is required for the SSL certificate generation to work properly."
echo ""
read -p "Have you configured the DNS A record for your domain? (y/n): " dns_configured
echo ""
if [ "$dns_configured" != "y" ] && [ "$dns_configured" != "Y" ]; then
  echo "Please set up your DNS records first, then run this script again."
  exit 1
fi
echo ""
echo "=================================================="
echo "PORT AVAILABILITY CHECK"
echo "=================================================="
echo ""
echo "IMPORTANT: This deployment requires ports 80 and 443 to be available."
echo "Port 80 is needed for HTTP traffic and initial SSL certificate setup."
echo "Port 443 is needed for HTTPS/SSL encrypted traffic."
echo ""
echo "If another service (like Apache or Nginx) is using these ports,"
echo "please stop those services before continuing."
echo ""
echo "NOTE: If you're using a cloud provider (AWS, GCP, Azure, DigitalOcean, Linode, etc.),"
echo "you may need to explicitly allow inbound traffic on ports 80 and 443"
echo "in your cloud provider's firewall or security group settings."
echo "Without this configuration, the ports may appear available on your server"
echo "but will still be inaccessible from the internet."
echo ""
# shellcheck disable=SC2162
read -p "Have you verified that ports 80 and 443 are available and exposed if needed? (y/n): " ports_available
echo ""
if [ "$ports_available" != "y" ] && [ "$ports_available" != "Y" ]; then
  echo "Please ensure ports 80 and 443 are available and properly exposed, then run this script again."
  exit 1
fi
echo ""
# This reliably gets the directory where the script is located, even if called via symlink or from another path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR%/*/*}"
COMPOSE_NOW() {
  docker compose -f "$ROOT_DIR"/docker-compose.yml "$@"
}
echo ""
source "$ROOT_DIR"/deployment/share/load-env.sh
echo ""
source "$ROOT_DIR"/deployment/share/nginx-none-ssl.sh
echo ""
echo "=================================================="
echo "RUN DOCKER WITH NGINX CONFIGURATION (NONE SSL)"
echo "=================================================="
echo ""
COMPOSE_NOW up -d --build --remove-orphans --force-recreate
echo ""
echo "=================================================="
echo "SSL MOUNT STATUS"
echo "=================================================="
echo ""
echo "Waiting for the webserver container to be ready..."
sleep 5
echo ""
# shellcheck disable=SC1009
if COMPOSE_NOW exec webserver test -d /etc/letsencrypt/live; then
  echo "✅ SSL certificates already exist"
  echo ""
else
  echo "❌ Directory /etc/letsencrypt/live does NOT exist in the webserver container"
  echo ""
  echo "=================================================="
  echo "GET SSL CERTIFICATES"
  echo "=================================================="
  echo ""
  COMPOSE_NOW up --force-recreate --no-deps certbot
  echo ""
  echo "Waiting for SSL certificates to be generated..."

  # Wait for the certificates to become available, with timeout
  MAX_RETRIES=50
  RETRY_COUNT=0
  while ! COMPOSE_NOW exec webserver test -d /etc/letsencrypt/live; do
    echo "Waiting for certificates... ($(( MAX_RETRIES - RETRY_COUNT )) attempts remaining)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT+1))

    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      echo "❌ Timed out waiting for SSL certificates"
      echo "Please check the certbot logs and try again"
      exit 1
    fi
  done

  echo "✅ SSL certificates successfully generated!"
  echo ""
fi

echo "=================================================="
echo "APPLYING SSL CONFIGURATION"
echo "=================================================="
echo ""
source "$ROOT_DIR"/deployment/share/nginx-with-ssl.sh
echo ""