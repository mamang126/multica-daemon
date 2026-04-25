#!/bin/bash
set -e

echo "Multica Daemon starting..."
echo "Server URL: ${MULTICA_SERVER_URL}"
echo "App URL: ${MULTICA_APP_URL}"

# Configure git authentication
echo "Configuring git authentication..."

# METHOD 1: SSH Key Authentication
if [ -f "/home/multica/.ssh/id_rsa" ]; then
  echo "Using SSH key authentication for git..."
  chmod 600 /home/multica/.ssh/id_rsa
  
  # Add common git hosts to known_hosts if not already present
  if [ ! -f "/home/multica/.ssh/known_hosts" ]; then
    echo "Adding common git hosts to known_hosts..."
    mkdir -p /home/multica/.ssh
    ssh-keyscan -t rsa github.com >> /home/multica/.ssh/known_hosts 2>/dev/null || true
    ssh-keyscan -t rsa gitlab.com >> /home/multica/.ssh/known_hosts 2>/dev/null || true
    ssh-keyscan -t rsa bitbucket.org >> /home/multica/.ssh/known_hosts 2>/dev/null || true
    chmod 644 /home/multica/.ssh/known_hosts
  fi
  
  echo "SSH key configured for git access"
fi

# METHOD 2: HTTPS with Personal Access Token
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_TOKEN" ]; then
  echo "Using HTTPS token authentication for git..."
  
  # Configure credential helper
  if [ -n "$GIT_CREDENTIAL_HELPER" ]; then
    echo "Setting git credential helper to: ${GIT_CREDENTIAL_HELPER}"
    git config --global credential.helper "${GIT_CREDENTIAL_HELPER}"
  fi
  
  # Create git credentials file for common providers
  echo "Configuring git credentials..."
  cat > /home/multica/.git-credentials << EOF
https://${GIT_USERNAME}:${GIT_TOKEN}@github.com
https://${GIT_USERNAME}:${GIT_TOKEN}@gitlab.com
https://${GIT_USERNAME}:${GIT_TOKEN}@bitbucket.org
EOF
  chmod 600 /home/multica/.git-credentials
  
  echo "HTTPS token authentication configured"
fi

# Configure git user if provided
if [ -n "$GIT_USER_NAME" ]; then
  echo "Configuring git user name: ${GIT_USER_NAME}"
  git config --global user.name "${GIT_USER_NAME}"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
  echo "Configuring git user email: ${GIT_USER_EMAIL}"
  git config --global user.email "${GIT_USER_EMAIL}"
fi

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
