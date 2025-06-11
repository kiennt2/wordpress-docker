#!/bin/bash

set -e

# Update and upgrade system packages
apt-get update && apt-get upgrade -y

# Install required dependencies
apt-get install -y vim wget gcc make build-essential autoconf automake libtool libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep gettext pkg-config libgeoip-dev libyajl-dev doxygen libpcre3-dev libpcre2-dev libpcre2-16-0 libpcre2-dev libpcre2-posix3 zlib1g zlib1g-dev git

# Configure Git for ModSecurity
git config --global user.name "ModSecurity Docker"
git config --global user.email "git@ModSecurity.com"

# Clone ModSecurity repository
cd /opt
git clone https://github.com/owasp-modsecurity/ModSecurity.git

# Build and install ModSecurity
cd /opt/ModSecurity
git tag
git checkout tags/v3.0.14
git submodule init
git submodule update
./build.sh
./configure
make
make install

# Clone ModSecurity-nginx repository
cd /opt
git clone https://github.com/SpiderLabs/ModSecurity-nginx.git
cd /opt/ModSecurity-nginx
git tag
git checkout tags/v1.0.4

# Download and extract Nginx source
cd /opt
wget https://nginx.org/download/nginx-1.28.0.tar.gz
tar -xzvf nginx-1.28.0.tar.gz
rm nginx-1.28.0.tar.gz
# Build Nginx with ModSecurity module
cd /opt/nginx-1.28.0
./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx
make
make modules

# Copy the modules to nginx modules, also copy configuration of modsecurity and unicode.
mkdir -p /etc/nginx/modules-enabled/
cp ./objs/ngx_http_modsecurity_module.so /etc/nginx/modules-enabled/
cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.conf
cp /opt/ModSecurity/unicode.mapping /etc/nginx/unicode.mapping

# load the ModSecurity module in Nginx configuration
nginx_conf_file="/etc/nginx/nginx.conf"
module_line="load_module /etc/nginx/modules-enabled/ngx_http_modsecurity_module.so;"
# Insert the line after the third line
sed -i "3a $module_line" "$nginx_conf_file"

# Change SecRuleEngine to On
mod_conf_file="/etc/nginx/modsecurity.conf"
SreOption="SecRuleEngine On"
# If SecRuleEngine exists, replace its value with On; otherwise, add it at the end
if grep -q "^SecRuleEngine" "$mod_conf_file"; then
    sed -i "s/^SecRuleEngine.*/$SreOption/" "$mod_conf_file"
else
    echo "$SreOption" >> "$mod_conf_file"
fi

#######################################################################################
# Update Rule with CORE RULE SET (CRS)
#######################################################################################
cd /etc/nginx/
git clone https://github.com/coreruleset/coreruleset.git owasp-crs
cd /etc/nginx/owasp-crs
git tag
git checkout tags/v4.15.0
cp /etc/nginx/owasp-crs/crs-setup.conf{.example,}
echo 'Include /etc/nginx/owasp-crs/crs-setup.conf' >> "$mod_conf_file"
echo 'Include /etc/nginx/owasp-crs/rules/*.conf' >> "$mod_conf_file"

nginx -t
service nginx stop
service nginx start