FROM nikolaik/python-nodejs:python3.12-nodejs22-bookworm

ENV NODE_ENV=production
ENV PORT=2633

# Install system dependencies (removed FUSE and TigrisFS)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      wget \
      unzip \
      git; \
    \
    # Install AWS CLI for S3 operations
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"; \
    unzip awscliv2.zip; \
    ./aws/install; \
    rm -rf aws awscliv2.zip; \
    \
    # Install OpenCode
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; \
    mv /root/.opencode/bin/opencode /usr/local/bin/opencode; \
    \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy preset config
COPY config /opt/config-init

# Install Node.js dependencies for S3 operations
RUN npm install -g aws-sdk @aws-sdk/client-s3 @aws-sdk/lib-storage

# Create startup script without FUSE dependencies
RUN install -m 755 /dev/stdin /entrypoint.sh <<'EOF'
#!/bin/bash
set -e

WORKSPACE_DIR="/root/workspace"
XDG_DIR="/root/.opencode"
GLOBAL_CONFIG_DIR="$XDG_DIR/config/opencode"
CONFIG_INIT_DIR="/opt/config-init/opencode"

# Initialize workspace and XDG environment variables
setup_workspace() {
    mkdir -p "$WORKSPACE_DIR/project" "$GLOBAL_CONFIG_DIR" "$XDG_DIR"/{data,state}
    export XDG_CONFIG_HOME="$XDG_DIR/config"
    export XDG_DATA_HOME="$XDG_DIR/data"
    export XDG_STATE_HOME="$XDG_DIR/state"
    PROJECT_DIR="$WORKSPACE_DIR/project"

    # Copy config files only if they don't exist
    for file in opencode.json AGENTS.md; do
        if [ ! -f "$GLOBAL_CONFIG_DIR/$file" ]; then
            cp "$CONFIG_INIT_DIR/$file" "$GLOBAL_CONFIG_DIR/" 2>/dev/null && echo "[INFO] Initialized $file" || true
        fi
    done
}

# Setup S3 sync without FUSE mounting
setup_s3_sync() {
    if [ -n "$S3_ENDPOINT" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ]; then
        echo "[INFO] Setting up S3 configuration for direct access"

        export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
        export AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"
        export AWS_DEFAULT_REGION="${S3_REGION:-auto}"
        export AWS_ENDPOINT_URL="$S3_ENDPOINT"

        # Create AWS config
        mkdir -p ~/.aws
        cat > ~/.aws/config <<EOL
[default]
region = ${S3_REGION:-auto}
output = json
s3 =
    endpoint_url = $S3_ENDPOINT
    addressing_style = ${S3_PATH_STYLE:-path}
EOL

        cat > ~/.aws/credentials <<EOL
[default]
aws_access_key_id = $S3_ACCESS_KEY_ID
aws_secret_access_key = $S3_SECRET_ACCESS_KEY
EOL

        # Test S3 connection
        if aws s3 ls "s3://$S3_BUCKET/${S3_PREFIX:-}" --endpoint-url="$S3_ENDPOINT" >/dev/null 2>&1; then
            echo "[OK] S3 connection successful"

            # Sync existing files from S3 to local workspace
            echo "[INFO] Syncing files from S3..."
            aws s3 sync "s3://$S3_BUCKET/${S3_PREFIX:-}" "$WORKSPACE_DIR/" --endpoint-url="$S3_ENDPOINT" --quiet || true

            # Setup periodic sync (every 5 minutes)
            (
                while true; do
                    sleep 300  # 5 minutes
                    echo "[INFO] Syncing workspace to S3..."
                    aws s3 sync "$WORKSPACE_DIR/" "s3://$S3_BUCKET/${S3_PREFIX:-}" --endpoint-url="$S3_ENDPOINT" --quiet --delete || true
                done
            ) &
            SYNC_PID=$!
            echo "[INFO] Background S3 sync started (PID: $SYNC_PID)"
        else
            echo "[WARN] S3 connection failed, using local storage only"
        fi
    else
        echo "[INFO] No S3 configuration, using local storage only"
    fi
}

setup_workspace
setup_s3_sync

cleanup() {
    echo "[INFO] Shutting down..."

    # Final sync to S3 before shutdown
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$S3_BUCKET" ]; then
        echo "[INFO] Final sync to S3..."
        aws s3 sync "$WORKSPACE_DIR/" "s3://$S3_BUCKET/${S3_PREFIX:-}" --endpoint-url="$S3_ENDPOINT" --quiet --delete || true
    fi

    if [ -n "$OPENCODE_PID" ]; then
        kill -TERM "$OPENCODE_PID" 2>/dev/null || true
        wait "$OPENCODE_PID" 2>/dev/null || true
    fi

    if [ -n "$SYNC_PID" ]; then
        kill -TERM "$SYNC_PID" 2>/dev/null || true
    fi

    exit 0
}
trap cleanup SIGTERM SIGINT

# Use PORT environment variable from Zeabur, fallback to 2633
LISTEN_PORT="${PORT:-2633}"
echo "[INFO] Starting OpenCode on port $LISTEN_PORT..."
cd "$PROJECT_DIR"

# Start OpenCode
opencode web --port "$LISTEN_PORT" --hostname 0.0.0.0 &
OPENCODE_PID=$!

echo "[INFO] OpenCode started with PID $OPENCODE_PID"
echo "[INFO] Workspace: $WORKSPACE_DIR"
echo "[INFO] Health check available at http://0.0.0.0:$LISTEN_PORT"

wait $OPENCODE_PID
EOF

WORKDIR /root/workspace
EXPOSE 2633

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:${PORT:-2633}/ || exit 1

CMD ["/entrypoint.sh"]