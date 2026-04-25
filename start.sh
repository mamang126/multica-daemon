#!/bin/bash
set -e

echo "Multica Daemon starting..."
echo "Server URL: ${MULTICA_SERVER_URL}"
echo "App URL: ${MULTICA_APP_URL}"

# Configure MCP for different agent CLIs
echo "Configuring MCP for agent CLIs..."

# Check if mcp.json exists and create agent-specific configuration files
if [ -f "/home/multica/.multica/mcp.json" ]; then
  echo "Found mcp.json, creating agent-specific configurations..."
  
  # OpenCode expects opencode.json in the home directory
  if command -v opencode &> /dev/null; then
    echo "  Creating opencode.json for OpenCode CLI..."
    mkdir -p /home/multica/.opencode
    cp /home/multica/.multica/mcp.json /home/multica/.opencode/opencode.json
    # Also symlink to alternative locations OpenCode might check
    ln -sf /home/multica/.opencode/opencode.json /home/multica/opencode.json 2>/dev/null || true
  fi
  
  # Claude expects claude_desktop_config.json
  if command -v claude &> /dev/null; then
    echo "  Creating claude_desktop_config.json for Claude CLI..."
    mkdir -p /home/multica/.config/Claude
    cp /home/multica/.multica/mcp.json /home/multica/.config/Claude/claude_desktop_config.json
  fi
  
  # GitHub Copilot might use different config paths
  if command -v copilot &> /dev/null; then
    echo "  Creating config for GitHub Copilot CLI..."
    mkdir -p /home/multica/.github-copilot
    cp /home/multica/.multica/mcp.json /home/multica/.github-copilot/mcp.json
  fi
  
  # OpenClaw configuration
  if command -v openclaw &> /dev/null; then
    echo "  Creating config for OpenClaw CLI..."
    mkdir -p /home/multica/.openclaw
    cp /home/multica/.multica/mcp.json /home/multica/.openclaw/mcp.json
  fi
  
  # Cursor configuration
  if command -v cursor &> /dev/null; then
    echo "  Creating config for Cursor CLI..."
    mkdir -p /home/multica/.cursor
    cp /home/multica/.multica/mcp.json /home/multica/.cursor/mcp.json
  fi
  
  echo "  ✓ Agent-specific MCP configurations created"
else
  echo "  No mcp.json found, skipping agent MCP configuration"
fi

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
