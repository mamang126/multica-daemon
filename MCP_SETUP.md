# MCP (Model Context Protocol) Configuration Guide

This guide explains how to configure and use MCP servers with your Multica daemon.

## What is MCP?

MCP (Model Context Protocol) is an open protocol that standardizes how applications provide context to AI models. MCP servers can provide:

- **Tools**: Functions the AI can call
- **Resources**: Data the AI can read
- **Prompts**: Pre-defined templates and workflows

## Configuration File

The `mcp.json` file defines which MCP servers are available to your AI agents. It's mounted at `/home/multica/.multica/mcp.json` in the container.

### Basic Structure

```json
{
  "$schema": "https://modelcontextprotocol.io/schema/mcp.json",
  "mcpServers": {
    "server-name": {
      "command": "executable",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      },
      "disabled": false
    }
  }
}
```

## Built-in MCP Servers

### 1. Filesystem Server

Provides access to files in your workspace.

```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-filesystem",
      "/home/multica/multica_workspaces"
    ],
    "env": {}
  }
}
```

**Capabilities:**
- Read files
- Write files
- List directories
- Search files

### 2. Git Server

Enables Git operations on repositories.

```json
{
  "git": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-git"
    ],
    "env": {}
  }
}
```

**Capabilities:**
- Git status
- Commit changes
- Create branches
- View diffs
- Push/pull

### 3. GitHub Server

Integrates with GitHub API for repository management.

```json
{
  "github": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-github"
    ],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

**Requirements:**
- GitHub Personal Access Token in your `.env` file:
  ```bash
  GITHUB_TOKEN=ghp_your_token_here
  ```

**Capabilities:**
- Create/manage issues
- Create/manage pull requests
- Search repositories
- Manage branches
- View repository contents

**Token Scopes Required:**
- `repo` (full repository access)
- `read:org` (read organization data)
- `user` (read user data)

### 4. Memory Server

Provides persistent memory storage across sessions.

```json
{
  "memory": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-memory"
    ],
    "env": {}
  }
}
```

**Capabilities:**
- Store key-value pairs
- Retrieve stored information
- Update memory
- Clear memory

**Use Cases:**
- Remember user preferences
- Store project-specific context
- Maintain conversation history

### 5. PostgreSQL Server

Connects to PostgreSQL databases for data access.

```json
{
  "postgres": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-postgres",
      "postgresql://user:password@host:5432/database"
    ],
    "env": {},
    "disabled": true
  }
}
```

**Requirements:**
- PostgreSQL database URL in your `.env` file:
  ```bash
  DATABASE_URL=postgresql://user:password@host:5432/database
  ```

**Capabilities:**
- Execute SQL queries
- List tables and schemas
- Describe table structure
- Insert/update/delete data

**Security Note:** Always use read-only credentials when possible.

## Adding Custom MCP Servers

### Example: Slack MCP Server

```json
{
  "slack": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-slack"
    ],
    "env": {
      "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
      "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
    }
  }
}
```

Then add to your `.env`:
```bash
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_TEAM_ID=T1234567890
```

### Example: Custom Python MCP Server

```json
{
  "my-custom-server": {
    "command": "python",
    "args": [
      "/path/to/your/mcp_server.py"
    ],
    "env": {
      "CUSTOM_API_KEY": "${CUSTOM_API_KEY}"
    }
  }
}
```

## Environment Variable Substitution

MCP configuration supports environment variable substitution using `${VAR_NAME}` syntax:

```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}",
    "BASE_URL": "${SERVICE_URL}"
  }
}
```

These variables are passed from your Docker environment (defined in `.env` or `docker-compose.yml`).

## Disabling MCP Servers

To temporarily disable a server without removing it:

```json
{
  "postgres": {
    "command": "npx",
    "args": ["..."],
    "disabled": true
  }
}
```

## Troubleshooting

### Server Not Starting

1. **Check logs:**
   ```bash
   docker-compose logs multica-daemon
   ```

2. **Verify environment variables:**
   ```bash
   docker-compose exec multica-daemon env | grep GITHUB_TOKEN
   ```

3. **Test npx access:**
   ```bash
   docker-compose exec multica-daemon npx -y @modelcontextprotocol/server-github --version
   ```

### Token Issues

If GitHub or other API integrations fail:

1. Verify token is set in `.env`
2. Check token has required permissions
3. Ensure token is not expired
4. Restart container after changing `.env`:
   ```bash
   docker-compose down && docker-compose up -d
   ```

### Performance Issues

If MCP servers are slow:

1. Disable unused servers
2. Use specific paths for filesystem server (not root)
3. Consider resource limits in docker-compose.yml

## Best Practices

1. **Security:**
   - Never commit tokens to version control
   - Use read-only database credentials
   - Limit filesystem access to necessary directories
   - Use minimal token scopes

2. **Performance:**
   - Only enable servers you need
   - Use specific paths, not broad access
   - Monitor resource usage

3. **Maintenance:**
   - Keep MCP packages updated
   - Document custom servers
   - Test after configuration changes
   - Back up mcp.json with your code

## Additional Resources

- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Server List](https://github.com/modelcontextprotocol/servers)
- [Creating Custom MCP Servers](https://modelcontextprotocol.io/docs/creating-servers)

## Example Complete Configuration

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

Corresponding `.env`:
```bash
GITHUB_TOKEN=ghp_your_github_token_here
```
