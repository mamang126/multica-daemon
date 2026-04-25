# Multica Daemon Dockerfile
# Connects to a self-hosted Multica instance using token authentication

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    tar \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the daemon
RUN useradd -m -s /bin/bash multica

# Download and install Multica CLI
RUN OS=$(uname -s | tr '[:upper:]' '[:lower:]') && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    LATEST=$(curl -sI https://github.com/multica-ai/multica/releases/latest | grep -i '^location:' | sed 's/.*tag\///' | tr -d '\r\n') && \
    VERSION="${LATEST#v}" && \
    echo "Downloading Multica CLI version ${VERSION} for ${OS}-${ARCH}" && \
    curl -sL "https://github.com/multica-ai/multica/releases/download/${LATEST}/multica-cli-${VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/multica.tar.gz && \
    tar -xzf /tmp/multica.tar.gz -C /tmp multica && \
    mv /tmp/multica /usr/local/bin/multica && \
    chmod +x /usr/local/bin/multica && \
    rm /tmp/multica.tar.gz

# Verify installation
RUN multica version

# Switch to non-root user
USER multica
WORKDIR /home/multica

# Environment variables for configuration
# These should be provided at runtime
ENV MULTICA_TOKEN="" \
    MULTICA_SERVER_URL="http://localhost:8080" \
    MULTICA_APP_URL="http://localhost:3000" \
    MULTICA_DAEMON_POLL_INTERVAL="3s" \
    MULTICA_DAEMON_HEARTBEAT_INTERVAL="15s" \
    MULTICA_DAEMON_MAX_CONCURRENT_TASKS="20"

# Copy startup script
COPY --chown=multica:multica start.sh /home/multica/start.sh
RUN chmod +x /home/multica/start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD multica daemon status || exit 1

# Expose default health port (if needed)
# The daemon uses a health port for status checks
EXPOSE 8081

# Start the daemon
CMD ["/home/multica/start.sh"]
