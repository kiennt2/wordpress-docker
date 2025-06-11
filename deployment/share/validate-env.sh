#!/bin/bash

echo "=================================================="
echo "VALIDATE SENSITIVE VARIABLES"
echo "=================================================="
echo ""
env_FILE="$ROOT_DIR"/.env
env_EXAMPLE_FILE="$ROOT_DIR"/.env.example

# Check if both files exist
if [ ! -f "$env_FILE" ]; then
    echo "Error: $env_FILE does not exist"
    exit 1
fi

if [ ! -f "$env_EXAMPLE_FILE" ]; then
    echo "Error: $env_EXAMPLE_FILE does not exist"
    exit 1
fi

# Variables that must be different from examples
VARS_TO_CHECK=(
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_USER"
    "MYSQL_PASSWORD"
    "REDIS_PASSWORD"
)

# Check if security-sensitive variables have been changed from example values
echo "Checking if sensitive variables have been changed from example values..."
echo ""
HAS_ERROR=0

for VAR in "${VARS_TO_CHECK[@]}"; do
    # Extract value from .env file
    ENV_VALUE=$(grep "^$VAR=" "$env_FILE" | cut -d '=' -f2-)

    # Extract value from .env.example file
    EXAMPLE_VALUE=$(grep "^$VAR=" "$env_EXAMPLE_FILE" | cut -d '=' -f2-)

    # Check if values are the same
    if [ "$ENV_VALUE" = "$EXAMPLE_VALUE" ]; then
        echo "Error: $VAR in $env_FILE must be different from the example value in $env_EXAMPLE_FILE"
        echo ""
        HAS_ERROR=1
    fi
done

if [ $HAS_ERROR -eq 1 ]; then
    echo "Please update the sensitive variables in $env_FILE to be different from the example values."
    echo ""
    exit 1
fi

echo "All sensitive variables have been properly configured."
