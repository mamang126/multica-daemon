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
  
  # Function to safely create config file
  create_agent_config() {
    local agent_name="$1"
    local config_dir="$2"
    local config_file="$3"
    local symlink_path="$4"
    
    echo "  Creating config for ${agent_name}..."
    
    # Try to create directory
    if ! mkdir -p "${config_dir}" 2>/dev/null; then
      echo "    ⚠ Warning: Could not create ${config_dir} (permission denied)"
      echo "    This may be a volume permission issue. Trying alternative location..."
      return 1
    fi
    
    # Try to copy config file
    if ! cp /home/multica/.multica/mcp.json "${config_file}" 2>/dev/null; then
      echo "    ⚠ Warning: Could not create ${config_file} (permission denied)"
      return 1
    fi
    
    # Create symlink if specified
    if [ -n "${symlink_path}" ]; then
      ln -sf "${config_file}" "${symlink_path}" 2>/dev/null || true
    fi
    
    echo "    ✓ ${agent_name} configuration created"
    return 0
  }
  
  # OpenCode expects opencode.json
  if command -v opencode &> /dev/null; then
    create_agent_config "OpenCode" \
      "/home/multica/.opencode" \
      "/home/multica/.opencode/opencode.json" \
      "/home/multica/opencode.json"
  fi
  
  # Claude expects claude_desktop_config.json
  if command -v claude &> /dev/null; then
    create_agent_config "Claude" \
      "/home/multica/.config/Claude" \
      "/home/multica/.config/Claude/claude_desktop_config.json" \
      ""
  fi
  
  # GitHub Copilot configuration
  if command -v copilot &> /dev/null; then
    create_agent_config "GitHub Copilot" \
      "/home/multica/.github-copilot" \
      "/home/multica/.github-copilot/mcp.json" \
      ""
  fi
  
  # OpenClaw configuration
  if command -v openclaw &> /dev/null; then
    create_agent_config "OpenClaw" \
      "/home/multica/.openclaw" \
      "/home/multica/.openclaw/mcp.json" \
      ""
  fi
  
  # Cursor configuration
  if command -v cursor &> /dev/null; then
    create_agent_config "Cursor" \
      "/home/multica/.cursor" \
      "/home/multica/.cursor/mcp.json" \
      ""
  fi
  
  echo "  ✓ Agent MCP configuration complete"
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
