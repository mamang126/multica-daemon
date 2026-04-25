#!/bin/bash
# Note: Not using 'set -e' to allow continuing on individual agent failures

echo "=== Agent CLI Installation Script ==="

# Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names
if [ "$ARCH" = "x86_64" ]; then 
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then 
    ARCH="arm64"
fi

echo "Detected platform: ${OS}-${ARCH}"

# Install OpenCode CLI
if [ "$INSTALL_OPENCODE" = "true" ]; then
    echo "Installing OpenCode CLI..."
    LATEST=$(curl -sI https://github.com/anomalyco/opencode/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
    echo "  Version: ${LATEST}"
    
    DOWNLOAD_URL="https://github.com/anomalyco/opencode/releases/download/${LATEST}/opencode-${OS}-${ARCH}.tar.gz"
    echo "  Downloading from: ${DOWNLOAD_URL}"
    
    HTTP_CODE=$(curl -sL -w "%{http_code}" "${DOWNLOAD_URL}" -o /tmp/opencode.tar.gz)
    
    if [ "$HTTP_CODE" = "200" ] && file /tmp/opencode.tar.gz | grep -q "gzip compressed data"; then
        tar -xzf /tmp/opencode.tar.gz -C /tmp opencode
        mv /tmp/opencode /usr/local/bin/opencode
        chmod +x /usr/local/bin/opencode
        rm /tmp/opencode.tar.gz
        opencode version || echo "  (version command not available)"
        echo "  ✓ OpenCode CLI installed"
    else
        echo "  ✗ OpenCode CLI not available for ${OS}-${ARCH} (HTTP ${HTTP_CODE})"
        rm -f /tmp/opencode.tar.gz
        echo "  Skipping OpenCode CLI installation"
    fi
fi

# Install Claude CLI
if [ "$INSTALL_CLAUDE" = "true" ]; then
    echo "Installing Claude CLI..."
    curl -sL "https://claude.ai/download/cli/${OS}-${ARCH}" -o /usr/local/bin/claude
    chmod +x /usr/local/bin/claude
    echo "  ✓ Claude CLI installed"
fi

# Install OpenClaw CLI
if [ "$INSTALL_OPENCLAW" = "true" ]; then
    echo "Installing OpenClaw CLI..."
    LATEST=$(curl -sI https://github.com/openclaw-ai/openclaw/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
    VERSION="${LATEST#v}"
    echo "  Version: ${VERSION}"
    
    DOWNLOAD_URL="https://github.com/openclaw-ai/openclaw/releases/download/${LATEST}/openclaw-cli-${VERSION}-${OS}-${ARCH}.tar.gz"
    echo "  Downloading from: ${DOWNLOAD_URL}"
    
    HTTP_CODE=$(curl -sL -w "%{http_code}" "${DOWNLOAD_URL}" -o /tmp/openclaw.tar.gz)
    
    if [ "$HTTP_CODE" = "200" ] && file /tmp/openclaw.tar.gz | grep -q "gzip compressed data"; then
        tar -xzf /tmp/openclaw.tar.gz -C /tmp openclaw
        mv /tmp/openclaw /usr/local/bin/openclaw
        chmod +x /usr/local/bin/openclaw
        rm /tmp/openclaw.tar.gz
        openclaw version
        echo "  ✓ OpenClaw CLI installed"
    else
        echo "  ✗ OpenClaw CLI not available for ${OS}-${ARCH}"
        rm -f /tmp/openclaw.tar.gz
    fi
fi

# Install GitHub Copilot CLI
if [ "$INSTALL_COPILOT" = "true" ]; then
    echo "Installing GitHub Copilot CLI..."
    curl -sL "https://github.com/github/copilot-cli/releases/latest/download/copilot-${OS}-${ARCH}" -o /usr/local/bin/copilot
    chmod +x /usr/local/bin/copilot
    echo "  ✓ GitHub Copilot CLI installed"
fi

# Install Codex CLI
if [ "$INSTALL_CODEX" = "true" ]; then
    echo "Installing Codex CLI..."
    curl -sL "https://openai.com/downloads/codex-cli/${OS}-${ARCH}" -o /usr/local/bin/codex
    chmod +x /usr/local/bin/codex
    echo "  ✓ Codex CLI installed"
fi

# Install Hermes CLI
if [ "$INSTALL_HERMES" = "true" ]; then
    echo "Installing Hermes CLI..."
    LATEST=$(curl -sI https://github.com/hermes-ai/hermes/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
    VERSION="${LATEST#v}"
    echo "  Version: ${VERSION}"
    
    DOWNLOAD_URL="https://github.com/hermes-ai/hermes/releases/download/${LATEST}/hermes-cli-${VERSION}-${OS}-${ARCH}.tar.gz"
    echo "  Downloading from: ${DOWNLOAD_URL}"
    
    HTTP_CODE=$(curl -sL -w "%{http_code}" "${DOWNLOAD_URL}" -o /tmp/hermes.tar.gz)
    
    if [ "$HTTP_CODE" = "200" ] && file /tmp/hermes.tar.gz | grep -q "gzip compressed data"; then
        tar -xzf /tmp/hermes.tar.gz -C /tmp hermes
        mv /tmp/hermes /usr/local/bin/hermes
        chmod +x /usr/local/bin/hermes
        rm /tmp/hermes.tar.gz
        echo "  ✓ Hermes CLI installed"
    else
        echo "  ✗ Hermes CLI not available for ${OS}-${ARCH}"
        rm -f /tmp/hermes.tar.gz
    fi
fi

# Install Gemini CLI
if [ "$INSTALL_GEMINI" = "true" ]; then
    echo "Installing Gemini CLI..."
    curl -sL "https://dl.google.com/gemini/cli/${OS}-${ARCH}/gemini" -o /usr/local/bin/gemini
    chmod +x /usr/local/bin/gemini
    echo "  ✓ Gemini CLI installed"
fi

# Install Cursor Agent CLI
if [ "$INSTALL_CURSOR" = "true" ]; then
    echo "Installing Cursor Agent CLI..."
    LATEST=$(curl -sI https://github.com/getcursor/cursor-agent/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
    VERSION="${LATEST#v}"
    echo "  Version: ${VERSION}"
    
    DOWNLOAD_URL="https://github.com/getcursor/cursor-agent/releases/download/${LATEST}/cursor-agent-${VERSION}-${OS}-${ARCH}.tar.gz"
    echo "  Downloading from: ${DOWNLOAD_URL}"
    
    HTTP_CODE=$(curl -sL -w "%{http_code}" "${DOWNLOAD_URL}" -o /tmp/cursor.tar.gz)
    
    if [ "$HTTP_CODE" = "200" ] && file /tmp/cursor.tar.gz | grep -q "gzip compressed data"; then
        tar -xzf /tmp/cursor.tar.gz -C /tmp cursor-agent
        mv /tmp/cursor-agent /usr/local/bin/cursor-agent
        chmod +x /usr/local/bin/cursor-agent
        rm /tmp/cursor.tar.gz
        echo "  ✓ Cursor Agent CLI installed"
    else
        echo "  ✗ Cursor Agent CLI not available for ${OS}-${ARCH}"
        rm -f /tmp/cursor.tar.gz
    fi
fi

echo "=== Agent installation complete ==="
