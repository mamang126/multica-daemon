# Agent MCP Configuration Reference

This document provides a quick reference for how MCP configuration is distributed to different agent CLIs.

## Configuration Flow

```
mcp.json (your source file)
    ↓ (mounted to container)
/home/multica/.multica/mcp.json
    ↓ (distributed by start.sh at startup)
├── OpenCode     → /home/multica/.opencode/opencode.json
├── Claude       → /home/multica/.config/Claude/claude_desktop_config.json
├── Copilot      → /home/multica/.github-copilot/mcp.json
├── OpenClaw     → /home/multica/.openclaw/mcp.json
└── Cursor       → /home/multica/.cursor/mcp.json
```

## Agent Configuration Paths

### OpenCode
- **Primary Path**: `/home/multica/.opencode/opencode.json`
- **Symlink**: `/home/multica/opencode.json`
- **Created when**: `opencode` command is available
- **Format**: Standard MCP JSON

### Claude
- **Primary Path**: `/home/multica/.config/Claude/claude_desktop_config.json`
- **Created when**: `claude` command is available
- **Format**: Standard MCP JSON

### GitHub Copilot
- **Primary Path**: `/home/multica/.github-copilot/mcp.json`
- **Created when**: `copilot` command is available
- **Format**: Standard MCP JSON

### OpenClaw
- **Primary Path**: `/home/multica/.openclaw/mcp.json`
- **Created when**: `openclaw` command is available
- **Format**: Standard MCP JSON

### Cursor
- **Primary Path**: `/home/multica/.cursor/mcp.json`
- **Created when**: `cursor` command is available
- **Format**: Standard MCP JSON

## How It Works

1. **Edit Once**: You only edit `mcp.json` in your project root
2. **Automatic Distribution**: The `start.sh` script:
   - Detects which agents are installed
   - Creates agent-specific config files
   - Copies your `mcp.json` to the correct locations
3. **Consistent Configuration**: All agents use the same MCP servers

## Verifying Configuration

Check if configuration was applied correctly:

```bash
# View source configuration
docker-compose exec multica-daemon cat /home/multica/.multica/mcp.json

# Check OpenCode configuration
docker-compose exec multica-daemon cat /home/multica/.opencode/opencode.json

# Check Claude configuration
docker-compose exec multica-daemon cat /home/multica/.config/Claude/claude_desktop_config.json

# Check startup logs
docker-compose logs multica-daemon | grep -A 20 "Configuring MCP"
```

## Updating Configuration

To update MCP configuration:

1. Edit `mcp.json` in your project
2. Restart the container:
   ```bash
   docker-compose restart multica-daemon
   ```
3. Verify changes were applied (see commands above)

## Persistence

Agent configuration directories are stored in Docker volumes:
- `agent-config` - OpenCode configurations
- `agent-config-claude` - Claude configurations
- `agent-config-copilot` - Copilot configurations
- `agent-config-openclaw` - OpenClaw configurations
- `agent-config-cursor` - Cursor configurations

These volumes persist across container restarts but are regenerated from `mcp.json` on each startup, ensuring consistency.

## Troubleshooting

### Configuration not updating

If changes to `mcp.json` don't appear in agents:

1. **Check file is mounted**:
   ```bash
   docker-compose exec multica-daemon ls -la /home/multica/.multica/mcp.json
   ```

2. **Restart container** (not just daemon):
   ```bash
   docker-compose restart multica-daemon
   ```

3. **Check for syntax errors**:
   ```bash
   cat mcp.json | jq .
   ```

### Agent-specific path not created

If an agent's config file isn't created:

1. **Check if agent is installed**:
   ```bash
   docker-compose exec multica-daemon which opencode
   ```

2. **Review startup logs**:
   ```bash
   docker-compose logs multica-daemon | grep "Creating.*for.*CLI"
   ```

3. **Verify agent installation flag** in `.env`:
   ```bash
   grep INSTALL_OPENCODE .env
   ```

### Permission issues

If you see permission errors:

```bash
# Check file permissions
docker-compose exec multica-daemon ls -la /home/multica/.opencode/

# Fix permissions if needed (container should handle this automatically)
docker-compose exec multica-daemon chown -R multica:multica /home/multica/.opencode
```

## Environment Variable Substitution

MCP configuration supports environment variable substitution:

**In mcp.json:**
```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**In .env:**
```bash
GITHUB_TOKEN=ghp_your_token_here
```

**Result in container:**
The `${GITHUB_TOKEN}` placeholder is replaced with the actual token value from your environment.

## Advanced: Custom Agent Support

To add support for a new agent CLI:

1. **Edit start.sh** and add detection logic:
   ```bash
   if command -v newagent &> /dev/null; then
     echo "  Creating config for NewAgent CLI..."
     mkdir -p /home/multica/.newagent
     cp /home/multica/.multica/mcp.json /home/multica/.newagent/config.json
   fi
   ```

2. **Add volume in docker-compose.yml**:
   ```yaml
   volumes:
     - agent-config-newagent:/home/multica/.newagent
   ```

3. **Add volume definition**:
   ```yaml
   volumes:
     agent-config-newagent:
       driver: local
   ```

## References

- [OpenCode MCP Documentation](https://github.com/anomalyco/opencode)
- [Claude MCP Documentation](https://docs.anthropic.com/claude/docs/mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
