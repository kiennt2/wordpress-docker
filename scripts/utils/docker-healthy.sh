#!/bin/bash

echo "=================================================="
echo "WAITING FOR DOCKER CONTAINERS TO BE HEALTHY"
echo "=================================================="
echo ""
MAX_WAIT=120
START_TIME=$(date +%s)
echo "Waiting for containers to be ready (timeout: ${MAX_WAIT}s)..."
echo ""
COMPOSE_NOW up -d
# Wait for MySQL to be ready
while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
  if [ $ELAPSED_TIME -gt $MAX_WAIT ]; then
    echo "Timeout waiting for containers to be ready. Proceeding anyway, but import might fail."
    echo ""
    break
  fi
  if COMPOSE_NOW exec db mysqladmin ping -h localhost --silent; then
    echo "MySQL is ready!"
    echo ""
    break
  fi
  echo "Waiting for MySQL to be ready... (${ELAPSED_TIME}s elapsed)"
    echo ""
  sleep 2
done
echo "Ensuring WordPress is ready - sleep 5 seconds ..."
sleep 5