# Multica Daemon Dockerfile
# Connects to a self-hosted Multica instance using token authentication

FROM ubuntu:22.04

# Build arguments for agent CLI installation
ARG INSTALL_OPENCODE=true
ARG INSTALL_CLAUDE=false
ARG INSTALL_COPILOT=false
ARG INSTALL_CODEX=false
ARG INSTALL_OPENCLAW=false
ARG INSTALL_HERMES=false
ARG INSTALL_GEMINI=false
ARG INSTALL_CURSOR=false

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    tar \
    sudo \
    file \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the daemon
RUN useradd -m -s /bin/bash multica

# Create .multica config directory with proper permissions
RUN mkdir -p /home/multica/.multica && \
    chown -R multica:multica /home/multica/.multica

# Create .ssh directory with proper permissions for git SSH keys
RUN mkdir -p /home/multica/.ssh && \
    chown -R multica:multica /home/multica/.ssh && \
    chmod 700 /home/multica/.ssh

# Create workspace directory with proper permissions
RUN mkdir -p /home/multica/multica_workspaces && \
    chown -R multica:multica /home/multica/multica_workspaces

# Copy and run Multica CLI installation script
COPY install-multica.sh /tmp/install-multica.sh
RUN chmod +x /tmp/install-multica.sh && \
    /tmp/install-multica.sh && \
    rm /tmp/install-multica.sh

# Copy and run agent installation script
COPY install-agents.sh /tmp/install-agents.sh
RUN chmod +x /tmp/install-agents.sh && \
    INSTALL_OPENCODE=${INSTALL_OPENCODE} \
    INSTALL_CLAUDE=${INSTALL_CLAUDE} \
    INSTALL_COPILOT=${INSTALL_COPILOT} \
    INSTALL_CODEX=${INSTALL_CODEX} \
    INSTALL_OPENCLAW=${INSTALL_OPENCLAW} \
    INSTALL_HERMES=${INSTALL_HERMES} \
    INSTALL_GEMINI=${INSTALL_GEMINI} \
    INSTALL_CURSOR=${INSTALL_CURSOR} \
    /tmp/install-agents.sh && \
    rm /tmp/install-agents.sh

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
    MULTICA_DAEMON_MAX_CONCURRENT_TASKS="20" \
    GIT_USER_NAME="" \
    GIT_USER_EMAIL="" \
    GIT_USERNAME="" \
    GIT_TOKEN="" \
    GIT_CREDENTIAL_HELPER="store"

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
