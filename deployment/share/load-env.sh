#!/bin/bash

echo "=================================================="
echo "LOAD ENVIRONMENT VARIABLES"
echo "=================================================="
echo ""
# Load environment variables from .env file
if [ -f "${ROOT_DIR}/.env" ]; then
  # shellcheck disable=SC2046
  echo "${ROOT_DIR}/.env"
  # shellcheck disable=SC2046
  export $(grep -v '^#' "${ROOT_DIR}/.env" | xargs)
else
  echo "Error: .env file not found!"
  echo "Please create a .env file in the root directory of your project."
  echo ""
  exit 1
fi
