# Multica Daemon Docker Container

This Docker container runs a Multica daemon that connects to a self-hosted Multica instance using token-based authentication.

## Project Structure

**Core Files:**
- `Dockerfile` - Docker image definition
- `docker-compose.yml` - Docker Compose configuration
- `install-multica.sh` - Multica CLI installation script
- `install-agents.sh` - Agent CLI installation script
- `start.sh` - Daemon startup script (handles configuration and authentication)
- `.env.example` - Environment variables template

**MCP Configuration:**
- `mcp.json` - MCP (Model Context Protocol) server configuration (single source of truth)
- `mcp.json.example` - Example MCP configuration with common servers

**Documentation:**
- `README.md` - This file - project overview and setup
- `GIT_SETUP.md` - Git authentication configuration guide
- `TROUBLESHOOTING.md` - Common issues and solutions
- `MCP_QUICKSTART.md` - Quick start guide for MCP (start here!)
- `MCP_SETUP.md` - Detailed MCP server configuration
- `AGENT_CONFIG.md` - Agent-specific configuration reference
- `ARCHITECTURE.md` - Complete system architecture

## Prerequisites

- Docker installed on your system
- A self-hosted Multica instance running
- A personal access token from your Multica instance

## Quick Start

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` and add your configuration:**
   - Set `MULTICA_TOKEN` to your personal access token
   - Set `MULTICA_SERVER_URL` to your self-hosted API URL
   - Set `MULTICA_APP_URL` to your self-hosted app URL

3. **Build and start the container:**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

4. **Check the daemon status:**
   ```bash
   docker-compose exec multica-daemon multica daemon status
   ```

5. **View logs:**
   ```bash
   docker-compose logs -f multica-daemon
   ```

## Git Configuration for Private Repositories

If you need to clone private repositories, you can use either SSH keys or HTTPS with Personal Access Tokens. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions.

**Quick setup with SSH:**
1. Add to your `.env` file:
   ```bash
   SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa
   GIT_USER_NAME="Your Name"
   GIT_USER_EMAIL="your.email@example.com"
   ```
2. Rebuild: `docker-compose build && docker-compose up -d`

**Quick setup with HTTPS/Token (alternative):**
1. Add to your `.env` file:
   ```bash
   GIT_USERNAME=your-username
   GIT_TOKEN=your-personal-access-token
   GIT_USER_NAME="Your Name"
   GIT_USER_EMAIL="your.email@example.com"
   ```
2. Rebuild: `docker-compose build && docker-compose up -d`

## MCP (Model Context Protocol) Configuration

The daemon supports MCP servers to provide additional context and tools to AI assistants. The [mcp.json](mcp.json) file serves as the **single source of truth** and is automatically distributed to all installed agent CLIs at startup:

- **OpenCode** → `opencode.json`
- **Claude** → `claude_desktop_config.json`  
- **GitHub Copilot** → `mcp.json`
- **OpenClaw** → `mcp.json`
- **Cursor** → `mcp.json`

Simply edit `mcp.json` and restart the container - all agents will automatically use the updated configuration. 

**📚 Documentation:**
- **[MCP_QUICKSTART.md](MCP_QUICKSTART.md)** ⭐ Start here - 5-minute setup guide
- [MCP_SETUP.md](MCP_SETUP.md) - Detailed MCP server configuration guide
- [AGENT_CONFIG.md](AGENT_CONFIG.md) - Agent-specific configuration reference

### Quick Example

1. **Edit `mcp.json`** to add your MCP server:
   ```json
   {
     "mcpServers": {
       "outline": {
         "url": "https://documentation.example.com/mcp",
         "headers": {
           "Authorization": "${OUTLINE_API_KEY}"
         }
       }
     }
   }
   ```

2. **Set environment variables** in your `.env` file:
   ```bash
   OUTLINE_API_KEY=your_api_key_here
   ```

3. **Restart the container**:
   ```bash
   docker-compose up -d
   ```

## Configuration

### Required Environment Variables

- `MULTICA_TOKEN`: Your Multica authentication token (required)
- `MULTICA_SERVER_URL`: API server URL (default: `http://localhost:8080`)
- `MULTICA_APP_URL`: Web app URL (default: `http://localhost:3000`)

### Optional Environment Variables

- `MULTICA_DAEMON_POLL_INTERVAL`: How often to poll for tasks (default: `3s`)
- `MULTICA_DAEMON_HEARTBEAT_INTERVAL`: Heartbeat frequency (default: `15s`)
- `MULTICA_DAEMON_MAX_CONCURRENT_TASKS`: Max concurrent tasks (default: `20`)
- `MULTICA_AGENT_TIMEOUT`: Timeout for agent tasks (default: `2h`)
- `MULTICA_DAEMON_DEVICE_NAME`: Custom device name (default: hostname)

## Agent CLI Configuration

The Multica daemon requires at least one AI agent CLI to be installed. You can configure which agents to install using build-time arguments in your `.env` file:

### Available Agents

- **OpenCode** (`INSTALL_OPENCODE`): Open-source code assistant (default: `true`)
- **Claude** (`INSTALL_CLAUDE`): Anthropic's Claude CLI
- **GitHub Copilot** (`INSTALL_COPILOT`): GitHub Copilot CLI
- **Codex** (`INSTALL_CODEX`): OpenAI Codex CLI
- **OpenClaw** (`INSTALL_OPENCLAW`): OpenClaw agent CLI
- **Hermes** (`INSTALL_HERMES`): Hermes agent CLI
- **Gemini** (`INSTALL_GEMINI`): Google Gemini CLI
- **Cursor** (`INSTALL_CURSOR`): Cursor agent CLI

### Configuration Example

In your `.env` file:
```bash
# Agent CLI Installation (build-time configuration)
INSTALL_OPENCODE=true     # Enable OpenCode (default)
INSTALL_CLAUDE=false      # Disable Claude
INSTALL_COPILOT=true      # Enable GitHub Copilot
INSTALL_CODEX=false
INSTALL_OPENCLAW=false
INSTALL_HERMES=false
INSTALL_GEMINI=false
INSTALL_CURSOR=false
```

**Note:** After changing agent settings, you must rebuild the container:
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Verifying Installed Agents

Check which agents are available in your container:
```bash
docker-compose exec multica-daemon which opencode
docker-compose exec multica-daemon opencode version
```

## Using with Docker Run

If you prefer `docker run` instead of docker-compose:

```bash
docker build -t multica-daemon .

docker run -d \
  --name multica-daemon \
  -e MULTICA_TOKEN="your-token-here" \
  -e MULTICA_SERVER_URL="http://localhost:8080" \
  -e MULTICA_APP_URL="http://localhost:3000" \
  -v multica-config:/home/multica/.multica \
  -v multica-workspaces:/home/multica/multica_workspaces \
  multica-daemon
```

## Common Commands

```bash
docker-compose up -d                                      # Start the daemon
docker-compose down                                       # Stop the daemon
docker-compose restart                                    # Restart the daemon
docker-compose logs -f multica-daemon                     # View logs
docker-compose exec multica-daemon multica daemon status  # Check daemon status
docker-compose exec multica-daemon multica workspace list # List workspaces
docker-compose exec multica-daemon /bin/bash              # Open a shell in the container
```

## Managing the Container

**Start the daemon:**
```bash
docker-compose up -d
```

**Stop the daemon:**
```bash
docker-compose down
```

**Restart the daemon:**
```bash
docker-compose restart
```

**View logs:**
```bash
docker-compose logs -f multica-daemon
```

**Check daemon status:**
```bash
docker-compose exec multica-daemon multica daemon status
```

**List workspaces:**
```bash
docker-compose exec multica-daemon multica workspace list
```

## Troubleshooting

### Token Authentication Failed
- Ensure `MULTICA_TOKEN` is set correctly in `.env`
- Verify the token is valid and not expired
- Check that `MULTICA_SERVER_URL` points to the correct API endpoint

### Cannot Connect to Server
- Verify `MULTICA_SERVER_URL` is accessible from the container
- If connecting to localhost, use `host.docker.internal` or host network mode
- Check firewall settings

### No Agent CLI Found
- Ensure at least one agent is enabled in your `.env` file (e.g., `INSTALL_OPENCODE=true`)
- Rebuild the container after changing agent settings: `docker-compose build --no-cache`
- Verify agent installation: `docker-compose exec multica-daemon which opencode`

### View Daemon Logs
```bash
docker-compose exec multica-daemon multica daemon logs -f
```

### Git Permission Denied (publickey)
- Verify `SSH_PRIVATE_KEY_PATH` points to your SSH private key
- Ensure the public key is added to your git provider (GitHub, GitLab, etc.)
- Test SSH connection: `docker-compose exec multica-daemon ssh -T git@github.com`
- See [GIT_SETUP.md](GIT_SETUP.md) for detailed troubleshooting

### Git Authentication Failed (HTTPS)
- Verify `GIT_USERNAME` and `GIT_TOKEN` are set correctly in `.env`
- Ensure the token has required repository permissions
- Check token hasn't expired
- See [GIT_SETUP.md](GIT_SETUP.md) for detailed troubleshooting

## Persistent Data

Two volumes are created:
- `multica-config`: Stores Multica configuration and authentication
- `multica-workspaces`: Stores workspace data for task execution

To reset everything:
```bash
docker-compose down -v
```

## Health Check

The container includes a health check that runs every 30 seconds. Check container health with:
```bash
docker-compose ps
```

## Security Notes

- Never commit your `.env` file with real tokens to version control
- The `.env` file is already in `.gitignore`
- Use secrets management in production environments
- Consider using Docker secrets instead of environment variables for sensitive data

## License

This project follows the Multica project license.
