# Troubleshooting Guide

Common issues and solutions for the Multica daemon.

## Permission Errors

### Symptom
```
Creating opencode.json for OpenCode CLI...
cp: cannot create regular file '/home/multica/.opencode/opencode.json': Permission denied
```

### Cause
Docker volumes were created with incorrect permissions on first run.

### Solution 1: Quick Fix (Recreate Volumes)

Run the fix script:

**On Linux/Mac:**
```bash
chmod +x fix-permissions.sh
./fix-permissions.sh
```

**On Windows (PowerShell):**
```powershell
docker-compose down
docker volume rm milica-daemon_agent-config
docker volume rm milica-daemon_agent-config-claude
docker volume rm milica-daemon_agent-config-copilot
docker volume rm milica-daemon_agent-config-openclaw
docker volume rm milica-daemon_agent-config-cursor
docker-compose build --no-cache
docker-compose up -d
```

### Solution 2: Manual Fix

1. Stop the container:
   ```bash
   docker-compose down
   ```

2. Remove agent config volumes (this does NOT affect your workspaces or daemon config):
   ```bash
   docker volume ls | grep agent-config
   docker volume rm milica-daemon_agent-config
   docker volume rm milica-daemon_agent-config-claude
   docker volume rm milica-daemon_agent-config-copilot
   docker volume rm milica-daemon_agent-config-openclaw
   docker volume rm milica-daemon_agent-config-cursor
   ```

3. Rebuild and start:
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. Verify:
   ```bash
   docker-compose logs -f multica-daemon | grep -A 5 "Configuring MCP"
   ```

### Solution 3: Alternative Volume Configuration

If the issue persists, you can modify `docker-compose.yml` to not use separate volumes for agent configs. Edit the volumes section:

```yaml
volumes:
  # Persist Multica configuration (includes agent configs)
  - multica-config:/home/multica
  # Workspace directory for task execution
  - multica-workspaces:/home/multica/multica_workspaces
  # MCP configuration file (source of truth for all agents)
  - ./mcp.json:/home/multica/.multica/mcp.json:ro
```

This uses a single volume for the entire home directory.

## MCP Configuration Not Applied

### Symptom
Agents don't see MCP servers or configuration changes aren't reflected.

### Solution

1. **Verify mcp.json is mounted:**
   ```bash
   docker-compose exec multica-daemon cat /home/multica/.multica/mcp.json
   ```

2. **Check if configuration was distributed:**
   ```bash
   docker-compose logs multica-daemon | grep -i mcp
   ```

3. **Verify agent-specific configs:**
   ```bash
   docker-compose exec multica-daemon cat /home/multica/.opencode/opencode.json
   ```

4. **Restart after changes:**
   ```bash
   docker-compose restart multica-daemon
   ```

## Environment Variables Not Substituted

### Symptom
MCP servers show `${VARIABLE_NAME}` instead of actual values.

### Solution

1. **Check .env file exists:**
   ```bash
   cat .env | grep GITHUB_TOKEN
   ```

2. **Verify variables in docker-compose.yml:**
   Make sure environment variables are listed in the `environment:` section.

3. **Restart container (not just daemon):**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Agent Not Installed

### Symptom
```
command not found: opencode
```

### Solution

1. **Check installation flag in .env:**
   ```bash
   grep INSTALL_OPENCODE .env
   ```

2. **If false, change to true and rebuild:**
   ```bash
   # Edit .env
   INSTALL_OPENCODE=true
   
   # Rebuild
   docker-compose build --no-cache
   docker-compose up -d
   ```

3. **Verify installation:**
   ```bash
   docker-compose exec multica-daemon which opencode
   docker-compose exec multica-daemon opencode --version
   ```

## Container Won't Start

### Symptom
Container exits immediately or keeps restarting.

### Solution

1. **Check logs:**
   ```bash
   docker-compose logs multica-daemon
   ```

2. **Common causes:**
   - Missing `MULTICA_TOKEN` in .env
   - Invalid server URLs
   - Port conflicts
   - Volume permission issues

3. **Test configuration:**
   ```bash
   # Verify .env has required variables
   cat .env | grep MULTICA_TOKEN
   
   # Test without daemon mode
   docker-compose run --rm multica-daemon /bin/bash
   ```

## Git Authentication Failures

### Symptom
```
Permission denied (publickey)
fatal: Could not read from remote repository
```

### Solution

See [GIT_SETUP.md](GIT_SETUP.md) for detailed git authentication setup.

**Quick checks:**

1. **Verify SSH key is mounted:**
   ```bash
   docker-compose exec multica-daemon ls -la /home/multica/.ssh/
   ```

2. **Check git credentials:**
   ```bash
   docker-compose exec multica-daemon git config --global --list
   ```

3. **Test git access:**
   ```bash
   docker-compose exec multica-daemon ssh -T git@github.com
   ```

## Health Check Failing

### Symptom
```
Health check: unhealthy
```

### Solution

1. **Check daemon status:**
   ```bash
   docker-compose exec multica-daemon multica daemon status
   ```

2. **Verify authentication:**
   ```bash
   docker-compose exec multica-daemon multica auth status
   ```

3. **Check server connectivity:**
   ```bash
   docker-compose exec multica-daemon curl -v ${MULTICA_SERVER_URL}/health
   ```

## Complete Reset

If all else fails, completely reset the environment:

```bash
# Stop and remove everything
docker-compose down -v

# Remove all images
docker images | grep multica | awk '{print $3}' | xargs docker rmi -f

# Clean build cache
docker builder prune -af

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d

# Check logs
docker-compose logs -f multica-daemon
```

⚠️ **Warning**: This removes all volumes including workspaces!

## Getting Help

If issues persist:

1. **Gather diagnostic information:**
   ```bash
   echo "=== Docker Version ===" > debug.log
   docker --version >> debug.log
   docker-compose --version >> debug.log
   
   echo -e "\n=== Container Status ===" >> debug.log
   docker-compose ps >> debug.log
   
   echo -e "\n=== Container Logs ===" >> debug.log
   docker-compose logs --tail=100 multica-daemon >> debug.log
   
   echo -e "\n=== Volume List ===" >> debug.log
   docker volume ls | grep multica >> debug.log
   
   echo -e "\n=== Environment Check ===" >> debug.log
   docker-compose exec multica-daemon env | grep -v TOKEN >> debug.log
   ```

2. **Share debug.log** with your team or support

3. **Include:**
   - OS and Docker version
   - Contents of debug.log
   - Description of what you were trying to do
   - Any error messages

## Useful Commands

| Command | Purpose |
|---------|---------|
| `docker-compose logs -f multica-daemon` | View live logs |
| `docker-compose exec multica-daemon /bin/bash` | Shell into container |
| `docker-compose restart multica-daemon` | Restart daemon |
| `docker-compose down && docker-compose up -d` | Full restart |
| `docker-compose ps` | Check container status |
| `docker volume ls` | List all volumes |
| `docker system df` | Check disk usage |
| `docker system prune -a` | Clean up unused resources |
