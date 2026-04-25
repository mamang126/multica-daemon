# Multica Daemon Docker Container

This Docker container runs a Multica daemon that connects to a self-hosted Multica instance using token-based authentication.

## Project Structure

- `Dockerfile` - Docker image definition
- `docker-compose.yml` - Docker Compose configuration
- `start.sh` - Daemon startup script (handles configuration and authentication)
- `.env.example` - Environment variables template

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

### No Agents Detected
The daemon requires at least one supported AI CLI to be installed. The base Dockerfile doesn't include any agents. You would need to extend the Dockerfile to install agents like:
- Claude Code (`claude`)
- Codex (`codex`)
- OpenCode (`opencode`)
- Other supported agents

### View Daemon Logs
```bash
docker-compose exec multica-daemon multica daemon logs -f
```

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
