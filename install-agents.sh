#!/bin/bash
set -e

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
    LATEST=$(curl -sI https://github.com/opencode-ai/opencode/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
    VERSION="${LATEST#v}"
    echo "  Version: ${VERSION}"
    
    curl -sL "https://github.com/opencode-ai/opencode/releases/download/${LATEST}/opencode-cli-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/opencode.tar.gz
    tar -xzf /tmp/opencode.tar.gz -C /tmp opencode
    mv /tmp/opencode /usr/local/bin/opencode
    chmod +x /usr/local/bin/opencode
    rm /tmp/opencode.tar.gz
    
    opencode version
    echo "  ✓ OpenCode CLI installed"
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
    
    curl -sL "https://github.com/openclaw-ai/openclaw/releases/download/${LATEST}/openclaw-cli-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/openclaw.tar.gz
    tar -xzf /tmp/openclaw.tar.gz -C /tmp openclaw
    mv /tmp/openclaw /usr/local/bin/openclaw
    chmod +x /usr/local/bin/openclaw
    rm /tmp/openclaw.tar.gz
    
    openclaw version
    echo "  ✓ OpenClaw CLI installed"
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
    
    curl -sL "https://github.com/hermes-ai/hermes/releases/download/${LATEST}/hermes-cli-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/hermes.tar.gz
    tar -xzf /tmp/hermes.tar.gz -C /tmp hermes
    mv /tmp/hermes /usr/local/bin/hermes
    chmod +x /usr/local/bin/hermes
    rm /tmp/hermes.tar.gz
    echo "  ✓ Hermes CLI installed"
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
    
    curl -sL "https://github.com/getcursor/cursor-agent/releases/download/${LATEST}/cursor-agent-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/cursor.tar.gz
    tar -xzf /tmp/cursor.tar.gz -C /tmp cursor-agent
    mv /tmp/cursor-agent /usr/local/bin/cursor-agent
    chmod +x /usr/local/bin/cursor-agent
    rm /tmp/cursor.tar.gz
    echo "  ✓ Cursor Agent CLI installed"
fi

echo "=== Agent installation complete ==="
