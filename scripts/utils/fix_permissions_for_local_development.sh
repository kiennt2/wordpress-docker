#!/bin/bash

# try getting uid from docker, if it fails, try 33 (should work)
WWW_DATA_UID=33 # plug in your number from previous step
RESULT=$(COMPOSE_NOW exec -u www-data wordpress id -u)
COMMAND_SUCCESS=$?
if [ $COMMAND_SUCCESS -eq 0 ]; then
  WWW_DATA_UID=$(echo "$RESULT" | tr -d '\r')
fi

sudo chown -R "$WWW_DATA_UID":"$USER" "$ROOT_DIR"/source
sudo find "$ROOT_DIR"/source -type d -exec chmod 775 {} \;
sudo find "$ROOT_DIR"/source -type f -exec chmod 664 {} \;