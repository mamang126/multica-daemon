#!/bin/bash
set -e

echo "=== Multica CLI Installation Script ==="

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

# Get latest version
LATEST=$(curl -sI https://github.com/multica-ai/multica/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n')
VERSION="${LATEST#v}"

echo "Downloading Multica CLI version ${VERSION}..."

# Download and install
curl -sL "https://github.com/multica-ai/multica/releases/download/${LATEST}/multica-cli-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/multica.tar.gz
tar -xzf /tmp/multica.tar.gz -C /tmp multica
mv /tmp/multica /usr/local/bin/multica
chmod +x /usr/local/bin/multica
rm /tmp/multica.tar.gz

# Verify installation
multica version

echo "✓ Multica CLI installed successfully"
