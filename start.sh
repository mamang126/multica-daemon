#!/bin/bash
set -e

echo "Multica Daemon starting..."
echo "Server URL: ${MULTICA_SERVER_URL}"
echo "App URL: ${MULTICA_APP_URL}"

# Check if token is provided
if [ -z "$MULTICA_TOKEN" ]; then
  echo "ERROR: MULTICA_TOKEN environment variable is required"
  exit 1
fi

# Configure server URLs
echo "Configuring Multica for self-hosted instance..."
multica config set server_url "${MULTICA_SERVER_URL}"
multica config set app_url "${MULTICA_APP_URL}"

# Authenticate with token
echo "Authenticating with token..."
echo "${MULTICA_TOKEN}" | multica login --token

# Verify authentication
echo "Verifying authentication..."
multica auth status

# Start daemon in foreground
echo "Starting daemon in foreground..."
exec multica daemon start --foreground
