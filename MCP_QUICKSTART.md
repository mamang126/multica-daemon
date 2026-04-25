# MCP Quick Start Guide

Get your Multica daemon up and running with MCP servers in 5 minutes.

## Understanding the System

```
┌─────────────────────────────────────────────────────────┐
│  Your Project                                           │
│  ├── mcp.json (edit this!)                             │
│  └── .env (set API keys here)                          │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  Docker Container                                       │
│  ├── start.sh (automatic distribution)                 │
│  └── Agents                                             │
│      ├── OpenCode     → opencode.json                   │
│      ├── Claude       → claude_desktop_config.json      │
│      ├── Copilot      → mcp.json                        │
│      └── Others...    → mcp.json                        │
└─────────────────────────────────────────────────────────┘
```

**Key Principle**: Edit `mcp.json` once, all agents get the same configuration automatically.

## Step-by-Step Setup

### Step 1: Start with the Example

Copy the example configuration:

```bash
cp mcp.json.example mcp.json
```

Or use your current `mcp.json` (you already have one configured with Outline).

### Step 2: Configure Your MCP Servers

Edit `mcp.json` to enable/disable servers:

**Example: Enable GitHub and Filesystem**

```json
{
  "$schema": "https://modelcontextprotocol.io/schema/mcp.json",
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/multica/multica_workspaces"
      ],
      "disabled": false
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "disabled": false
    }
  }
}
```

### Step 3: Set Environment Variables

Add required API keys to your `.env` file:

```bash
# For GitHub MCP server
GITHUB_TOKEN=ghp_your_github_personal_access_token

# For your current Outline server
OUTLINE_API_KEY=ol_api_your_api_key
```

### Step 4: Restart Container

```bash
docker-compose restart multica-daemon
```

### Step 5: Verify Configuration

Check the logs to see MCP configuration being applied:

```bash
docker-compose logs multica-daemon | grep -A 10 "Configuring MCP"
```

You should see:
```
Configuring MCP for agent CLIs...
Found mcp.json, creating agent-specific configurations...
  Creating opencode.json for OpenCode CLI...
  ✓ Agent-specific MCP configurations created
```

## Common MCP Server Configurations

### 1. Documentation Access (Outline)

**Your current setup:**

```json
{
  "mcpServers": {
    "outline": {
      "url": "https://documentation.miwoo.es/mcp",
      "headers": {
        "Authorization": "${OUTLINE_API_KEY}"
      }
    }
  }
}
```

**In .env:**
```bash
OUTLINE_API_KEY=ol_api_your_key_here
```

**What it does**: Gives agents access to your documentation in Outline.

### 2. GitHub Integration

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
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

**Token scopes needed**: `repo`, `read:org`, `user`

**What it does**: Create issues, PRs, search repos, manage branches.

### 3. Filesystem Access

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/multica/multica_workspaces"
      ]
    }
  }
}
```

**No env vars needed**

**What it does**: Read/write files, list directories, search files in workspaces.

### 4. Git Operations

```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    }
  }
}
```

**No env vars needed** (uses git config from container)

**What it does**: Git status, commit, branch, diff, push/pull.

### 5. Persistent Memory

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

**No env vars needed**

**What it does**: Store/retrieve information across sessions.

## Combining Multiple Servers

You can enable multiple servers - agents will have access to all of them:

```json
{
  "mcpServers": {
    "outline": {
      "url": "https://documentation.miwoo.es/mcp",
      "headers": {
        "Authorization": "${OUTLINE_API_KEY}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/multica/multica_workspaces"
      ]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

## Disabling Servers

To temporarily disable a server without removing it:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["..."],
      "disabled": true
    }
  }
}
```

## Testing Your Configuration

### 1. Verify mcp.json is valid JSON

```bash
cat mcp.json | jq .
```

If you see formatted output, it's valid. If you see an error, fix the syntax.

### 2. Check environment variables in container

```bash
docker-compose exec multica-daemon env | grep -E "(GITHUB_TOKEN|OUTLINE_API_KEY)"
```

### 3. Verify agent configs were created

```bash
# Check OpenCode config
docker-compose exec multica-daemon cat /home/multica/.opencode/opencode.json

# Check if it matches your mcp.json
docker-compose exec multica-daemon cat /home/multica/.multica/mcp.json
```

### 4. Test with an agent

If you have OpenCode installed:

```bash
docker-compose exec multica-daemon opencode --help
```

## Troubleshooting

### Problem: Changes to mcp.json not appearing

**Solution**: Restart the container (not just the daemon)

```bash
docker-compose restart multica-daemon
```

### Problem: Environment variables not substituted

**Check:**
1. Variable is defined in `.env`
2. Variable is passed in `docker-compose.yml` under `environment:`
3. Restart container after changing `.env`

```bash
docker-compose down
docker-compose up -d
```

### Problem: MCP server failing to start

**Check logs:**
```bash
docker-compose logs multica-daemon
```

**Common causes:**
- Missing API key/token
- Invalid URL
- Server not available (check `npx` can access package)

### Problem: Agent not seeing MCP configuration

**Check if agent is installed:**
```bash
docker-compose exec multica-daemon which opencode
```

**Check installation flag in .env:**
```bash
grep INSTALL_OPENCODE .env
```

Should be `INSTALL_OPENCODE=true`

If it was false, change to true and rebuild:
```bash
docker-compose build --no-cache
docker-compose up -d
```

## Next Steps

- 📖 Read [MCP_SETUP.md](MCP_SETUP.md) for detailed server documentation
- 🔧 Read [AGENT_CONFIG.md](AGENT_CONFIG.md) for agent-specific configuration details
- 🌐 Browse [MCP Server Directory](https://github.com/modelcontextprotocol/servers) for more servers
- 💡 Check [modelcontextprotocol.io](https://modelcontextprotocol.io/) for MCP specification

## Quick Reference Card

| Task | Command |
|------|---------|
| View current config | `docker-compose exec multica-daemon cat /home/multica/.multica/mcp.json` |
| Check OpenCode config | `docker-compose exec multica-daemon cat /home/multica/.opencode/opencode.json` |
| View MCP logs | `docker-compose logs multica-daemon \| grep -i mcp` |
| Restart after changes | `docker-compose restart multica-daemon` |
| Rebuild container | `docker-compose build --no-cache && docker-compose up -d` |
| Test JSON validity | `cat mcp.json \| jq .` |
| Check environment | `docker-compose exec multica-daemon env \| grep TOKEN` |

## Configuration Template

Save this as your base `mcp.json`:

```json
{
  "$schema": "https://modelcontextprotocol.io/schema/mcp.json",
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/multica/multica_workspaces"
      ]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

Start with these three servers - they don't require API keys and provide core functionality. Add more as needed!
