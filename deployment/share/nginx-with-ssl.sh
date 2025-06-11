#!/bin/bash

echo "=================================================="
echo "NGINX CONFIGURATION - WITH SSL"
echo "=================================================="
echo ""
NGINX_CONF_TEMPLATE="${ROOT_DIR}/nginx-conf/nginx-with-ssl.conf.template"
NGINX_CONF="${ROOT_DIR}/nginx-conf/nginx.conf"
cp -f "$NGINX_CONF_TEMPLATE" "$NGINX_CONF"
PLACEHOLDER="domain_placeholder"

# Detect OS for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/${PLACEHOLDER}/${WEB_DOMAIN}/g" "$NGINX_CONF"
else
    # Linux and others
    sed -i "s/${PLACEHOLDER}/${WEB_DOMAIN}/g" "$NGINX_CONF"
fi
echo "Replaced all occurrences of $PLACEHOLDER with $WEB_DOMAIN in $NGINX_CONF"
echo ""
echo "=================================================="
echo "RUN DOCKER WITH NGINX CONFIGURATION (WITH SSL)"
echo "=================================================="
echo ""
COMPOSE_NOW down
COMPOSE_NOW up -d