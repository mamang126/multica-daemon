#!/bin/bash
# Permission fix script for Multica daemon volumes
# Run this if you encounter permission errors

echo "Fixing permissions for Multica daemon volumes..."
echo "This will recreate volumes with correct permissions."
echo ""

read -p "This will stop and remove the container. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Stop and remove container
echo "Stopping container..."
docker-compose down

# Remove volumes
echo "Removing volumes..."
docker volume rm milica-daemon_agent-config 2>/dev/null || true
docker volume rm milica-daemon_agent-config-claude 2>/dev/null || true
docker volume rm milica-daemon_agent-config-copilot 2>/dev/null || true
docker volume rm milica-daemon_agent-config-openclaw 2>/dev/null || true
docker volume rm milica-daemon_agent-config-cursor 2>/dev/null || true

echo ""
echo "⚠️  Note: The following volumes were NOT removed (they contain data):"
echo "  - multica-config (daemon configuration)"
echo "  - multica-workspaces (your workspaces)"
echo ""
echo "If you want to remove ALL volumes including data, run:"
echo "  docker-compose down -v"
echo ""

# Rebuild and start
echo "Rebuilding container with correct permissions..."
docker-compose build --no-cache
docker-compose up -d

echo ""
echo "✓ Done! Check logs with:"
echo "  docker-compose logs -f multica-daemon"
