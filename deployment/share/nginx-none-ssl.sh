#!/bin/bash

echo "=================================================="
echo "NGINX CONFIGURATION - NO SSL"
echo "=================================================="
echo ""
# Validate input
if [ -z "$WEB_DOMAIN" ]; then
    echo "No domain provided. Please update your .env file. Exiting without changes."
    echo ""
    exit 1
fi
NGINX_CONF_TEMPLATE="${ROOT_DIR}/nginx-conf/nginx-none-ssl.conf.template"
NGINX_CONF="${ROOT_DIR}/nginx-conf/nginx.conf"
cp -f "$NGINX_CONF_TEMPLATE" "$NGINX_CONF"

# Detect OS for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/server_name.*;/server_name ${WEB_DOMAIN};/" "$NGINX_CONF"
else
    # Linux and others
    sed -i "s/server_name.*;/server_name ${WEB_DOMAIN};/" "$NGINX_CONF"
fi
echo "Updated server_name in $NGINX_CONF to: $WEB_DOMAIN"