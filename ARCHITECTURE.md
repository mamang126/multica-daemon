# Multica Daemon Architecture with MCP

This document explains the complete architecture of the Multica daemon with MCP (Model Context Protocol) support.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Host Machine                                                   │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │ mcp.json       │  │ .env           │  │ docker-compose   │ │
│  │ (MCP Config)   │  │ (Secrets)      │  │ (Orchestration)  │ │
│  └────────────────┘  └────────────────┘  └──────────────────┘ │
│           │                   │                     │           │
│           └───────────────────┴─────────────────────┘           │
│                               ↓                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Docker Container: multica-daemon                         │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐│ │
│  │  │ start.sh - Initialization & Configuration            ││ │
│  │  │  1. Git authentication setup                         ││ │
│  │  │  2. MCP distribution to agents                       ││ │
│  │  │  3. Multica daemon startup                           ││ │
│  │  └──────────────────────────────────────────────────────┘│ │
│  │                               ↓                           │ │
│  │  ┌──────────────────────────────────────────────────────┐│ │
│  │  │ MCP Configuration Distribution                       ││ │
│  │  │                                                       ││ │
│  │  │  /home/multica/.multica/mcp.json (source)           ││ │
│  │  │           ↓                                           ││ │
│  │  │  ┌─────────────────┬──────────────┬─────────────┐   ││ │
│  │  │  ↓                 ↓              ↓             ↓   ││ │
│  │  │  OpenCode      Claude       Copilot      Others    ││ │
│  │  │  .opencode/    .config/     .github-     .cursor/  ││ │
│  │  │  opencode.json Claude/...   copilot/     mcp.json  ││ │
│  │  └──────────────────────────────────────────────────────┘│ │
│  │                               ↓                           │ │
│  │  ┌──────────────────────────────────────────────────────┐│ │
│  │  │ Installed Agent CLIs                                 ││ │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          ││ │
│  │  │  │ OpenCode │  │  Claude  │  │  Copilot │  ...     ││ │
│  │  │  └──────────┘  └──────────┘  └──────────┘          ││ │
│  │  │       ↕             ↕              ↕                 ││ │
│  │  │       └─────────────┴──────────────┘                 ││ │
│  │  │                     ↓                                 ││ │
│  │  │          Each agent reads its MCP config             ││ │
│  │  └──────────────────────────────────────────────────────┘│ │
│  │                               ↓                           │ │
│  │  ┌──────────────────────────────────────────────────────┐│ │
│  │  │ MCP Servers (spawned as needed)                      ││ │
│  │  │  ┌──────────────┐  ┌──────────────┐                 ││ │
│  │  │  │ Filesystem   │  │ Git          │                 ││ │
│  │  │  │ Server       │  │ Server       │                 ││ │
│  │  │  └──────────────┘  └──────────────┘                 ││ │
│  │  │  ┌──────────────┐  ┌──────────────┐                 ││ │
│  │  │  │ GitHub       │  │ Memory       │                 ││ │
│  │  │  │ Server       │  │ Server       │                 ││ │
│  │  │  └──────────────┘  └──────────────┘                 ││ │
│  │  │  ┌──────────────┐  ┌──────────────┐                 ││ │
│  │  │  │ Custom       │  │ Custom       │                 ││ │
│  │  │  │ Server 1     │  │ Server 2     │                 ││ │
│  │  │  └──────────────┘  └──────────────┘                 ││ │
│  │  └──────────────────────────────────────────────────────┘│ │
│  │                               ↕                           │ │
│  │  ┌──────────────────────────────────────────────────────┐│ │
│  │  │ Multica Daemon                                       ││ │
│  │  │  - Polls for tasks from Multica server              ││ │
│  │  │  - Executes tasks using appropriate agent CLI       ││ │
│  │  │  - Agents use MCP servers for enhanced context      ││ │
│  │  └──────────────────────────────────────────────────────┘│ │
│  │                               ↕                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                               ↕                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Persistent Volumes                                        │  │
│  │  - multica-config (daemon state)                         │  │
│  │  - multica-workspaces (task execution)                   │  │
│  │  - agent-config-* (agent configurations)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               ↕
┌─────────────────────────────────────────────────────────────────┐
│  Self-Hosted Multica Server                                     │
│  - Provides tasks to daemon                                     │
│  - Receives task results                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### Configuration Layer

#### mcp.json
- **Location**: Project root (host machine)
- **Purpose**: Single source of truth for all MCP server configurations
- **Format**: JSON with MCP specification
- **Mounted to**: `/home/multica/.multica/mcp.json` (read-only)

#### .env
- **Location**: Project root (host machine)
- **Purpose**: Stores secrets and environment variables
- **Contains**: 
  - Multica authentication tokens
  - MCP server API keys
  - Git credentials
  - Agent installation flags

### Initialization Layer (start.sh)

The startup script performs these operations in order:

1. **Git Authentication Setup**
   - Configure SSH keys (if provided)
   - Configure HTTPS tokens (if provided)
   - Set git user name and email

2. **MCP Configuration Distribution**
   ```bash
   if [ -f "/home/multica/.multica/mcp.json" ]; then
     # Detect installed agents
     # Copy mcp.json to agent-specific locations
     # Create necessary directories
   fi
   ```

3. **Multica Authentication**
   - Configure server URLs
   - Authenticate with token
   - Verify authentication

4. **Daemon Startup**
   - Start daemon in foreground mode
   - Handle signals gracefully

### Agent CLI Layer

Each agent CLI is installed conditionally based on build args:

| Agent | Binary | Config Path | Installed When |
|-------|--------|-------------|----------------|
| OpenCode | `/usr/local/bin/opencode` | `~/.opencode/opencode.json` | `INSTALL_OPENCODE=true` |
| Claude | `/usr/local/bin/claude` | `~/.config/Claude/claude_desktop_config.json` | `INSTALL_CLAUDE=true` |
| Copilot | `/usr/local/bin/copilot` | `~/.github-copilot/mcp.json` | `INSTALL_COPILOT=true` |
| OpenClaw | `/usr/local/bin/openclaw` | `~/.openclaw/mcp.json` | `INSTALL_OPENCLAW=true` |
| Cursor | `/usr/local/bin/cursor` | `~/.cursor/mcp.json` | `INSTALL_CURSOR=true` |

### MCP Server Layer

MCP servers are spawned on-demand by the agent CLIs:

#### Local Servers (run via npx)
- **filesystem**: Provides file system access
- **git**: Git operations
- **github**: GitHub API integration
- **memory**: Persistent key-value storage
- **postgres**: PostgreSQL database access

#### Remote Servers (HTTP/HTTPS)
- **outline**: Documentation access
- **custom**: Any HTTP-based MCP server

### Data Flow

```
Task Request
    ↓
Multica Server
    ↓
Multica Daemon (polls for tasks)
    ↓
Agent CLI (opencode/claude/etc.)
    ↓
MCP Servers (provide context & tools)
    │
    ├→ Filesystem Server (read/write files)
    ├→ Git Server (version control)
    ├→ GitHub Server (issues, PRs)
    ├→ Memory Server (persistent data)
    └→ Custom Servers (domain-specific)
    ↓
Agent generates response with enhanced context
    ↓
Multica Daemon (sends result)
    ↓
Multica Server
    ↓
User receives enhanced response
```

## Volume Mounts

### Configuration Volumes (Read-Only)
```yaml
- ./mcp.json:/home/multica/.multica/mcp.json:ro
```
- Host file mounted into container
- Read-only to prevent accidental modification
- Changes require container restart

### Persistent Volumes
```yaml
volumes:
  - multica-config:/home/multica/.multica           # Daemon state
  - multica-workspaces:/home/multica/multica_workspaces  # Task execution
  - agent-config:/home/multica/.opencode            # OpenCode config
  - agent-config-claude:/home/multica/.config/Claude    # Claude config
  - agent-config-copilot:/home/multica/.github-copilot  # Copilot config
  - agent-config-openclaw:/home/multica/.openclaw       # OpenClaw config
  - agent-config-cursor:/home/multica/.cursor           # Cursor config
```

### Git Volumes (Optional)
```yaml
# SSH authentication
- ${SSH_PRIVATE_KEY_PATH}:/home/multica/.ssh/id_rsa:ro
- ${SSH_CONFIG_PATH}:/home/multica/.ssh/config:ro
- ${SSH_KNOWN_HOSTS_PATH}:/home/multica/.ssh/known_hosts:ro
```

## Environment Variable Flow

```
.env file (host)
    ↓
Docker Compose reads .env
    ↓
Environment variables passed to container
    ↓
start.sh uses variables for configuration
    ↓
MCP config substitutes ${VARIABLE} syntax
    ↓
MCP servers receive actual values
```

**Example:**

`.env`:
```bash
GITHUB_TOKEN=ghp_abc123
```

`mcp.json`:
```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

Result in MCP server:
```bash
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_abc123
```

## Security Considerations

### Secrets Management
- ✅ Secrets in `.env` (gitignored)
- ✅ Mount mcp.json as read-only
- ✅ Use environment variable substitution
- ❌ Never commit tokens to git
- ❌ Never hardcode secrets in mcp.json

### Container Isolation
- Container runs as non-root user `multica`
- Limited file system access
- Network access controlled by Docker
- Volumes provide persistence without host access

### MCP Server Security
- Servers run with minimal privileges
- Filesystem server limited to workspace directory
- Database connections use connection strings (read-only recommended)
- API servers use token authentication

## Troubleshooting Decision Tree

```
Is MCP not working?
  │
  ├─ Are agents installed?
  │  └─ Check: docker-compose exec multica-daemon which opencode
  │     └─ No → Set INSTALL_OPENCODE=true, rebuild
  │
  ├─ Is mcp.json valid?
  │  └─ Check: cat mcp.json | jq .
  │     └─ Error → Fix JSON syntax
  │
  ├─ Are env vars set?
  │  └─ Check: docker-compose exec multica-daemon env | grep TOKEN
  │     └─ Missing → Add to .env, restart
  │
  ├─ Did config get distributed?
  │  └─ Check: docker-compose logs | grep "Configuring MCP"
  │     └─ No messages → Check start.sh execution
  │
  └─ Are MCP servers accessible?
     └─ Check: docker-compose logs | grep -i error
        └─ Errors → Check server URLs, tokens, network
```

## Build-Time vs Runtime

### Build-Time (docker-compose build)
- Agent CLIs are installed
- Base system configuration
- Cannot change without rebuild

**Triggers rebuild:**
- Changing `INSTALL_*` flags
- Modifying Dockerfile
- Changing installation scripts

### Runtime (docker-compose up)
- MCP configuration distributed
- Git authentication configured
- Daemon started

**No rebuild needed:**
- Editing mcp.json
- Changing environment variables in .env
- Updating git credentials

## Performance Characteristics

### Startup Time
1. Container start: ~1-2s
2. Git configuration: ~0.5s
3. MCP distribution: ~0.5s
4. Multica auth: ~1s
5. Daemon start: ~2s
**Total: ~5-6s**

### MCP Server Spawn Time
- First request: ~2-5s (npx downloads packages)
- Subsequent: ~0.1-0.5s (cached)

### Task Execution
- Without MCP: Agent baseline performance
- With MCP: +100-500ms per MCP server call
- Parallel MCP calls: Concurrent execution

## Extensibility Points

### Adding New Agents
1. Add installation logic to `install-agents.sh`
2. Add build arg to Dockerfile
3. Add environment variable to `.env.example`
4. Add detection and config distribution to `start.sh`
5. Add volume mounts to `docker-compose.yml`

### Adding New MCP Servers
1. Add server definition to `mcp.json`
2. Add required env vars to `.env`
3. Add env vars to `docker-compose.yml`
4. Restart container

### Custom MCP Servers
1. Package as npm module or Python script
2. Define in `mcp.json` with appropriate command
3. Mount custom server code if needed
4. Set environment variables

## Monitoring and Logging

### Container Logs
```bash
docker-compose logs -f multica-daemon
```

### MCP-Specific Logs
```bash
docker-compose logs multica-daemon | grep -i mcp
```

### Agent-Specific Logs
```bash
docker-compose logs multica-daemon | grep opencode
```

### Real-Time Monitoring
```bash
# Watch daemon status
watch -n 5 'docker-compose exec multica-daemon multica daemon status'

# Monitor resource usage
docker stats multica-daemon
```

## Best Practices

### Configuration Management
1. ✅ Keep `mcp.json` in version control
2. ✅ Use `.env.example` as template
3. ✅ Document custom MCP servers
4. ✅ Use comments in mcp.json (_comment fields)
5. ❌ Don't commit `.env` file

### Security
1. ✅ Use read-only mounts where possible
2. ✅ Limit filesystem server to workspace only
3. ✅ Use minimal token scopes
4. ✅ Rotate tokens regularly
5. ❌ Don't use root database credentials

### Performance
1. ✅ Disable unused MCP servers
2. ✅ Use specific paths for filesystem access
3. ✅ Cache MCP server responses when possible
4. ✅ Monitor resource usage
5. ❌ Don't enable all servers by default

### Maintenance
1. ✅ Keep agents updated (rebuild periodically)
2. ✅ Update MCP server packages
3. ✅ Review logs regularly
4. ✅ Test after configuration changes
5. ✅ Document custom configurations
