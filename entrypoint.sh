#!/bin/bash
set -e

# Set configurations for pre-downloaded models from the Docker build stage
export STORAGE_DIR="/models"
export MINERU_TOOLS_CONFIG_JSON="${STORAGE_DIR}/mineru.json"
export MINERU_MODEL_SOURCE="local"
export HOME="${STORAGE_DIR}"

# ====================================================================
# RUNPOD SERVERLESS COMPLIANCE: PORT & /ping HEALTHCHECK VIA NGINX
# ====================================================================

# RunPod injects these dynamically. Fallback to 8000 if not found.
LISTEN_PORT=${PORT:-8000}

# Create a dynamic Nginx configuration payload
cat << EOF > /etc/nginx/nginx.conf
user root;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    server {
        # Listen on the exact port RunPod expects
        listen $LISTEN_PORT;

        client_max_body_size 100M;  # Allow large PDF uploads

        # Runpod mandatory healthcheck
        location = /ping {
            access_log off;
            default_type text/plain;
            return 200 'OK';
        }

        # Main MinerU API Backend
        location / {
            proxy_pass http://127.0.0.1:8001;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_read_timeout 600s;
        }
    }
}
EOF

# Start NGINX in background to act as the traffic router
echo "[*] Starting Nginx Proxy on PORT $LISTEN_PORT..."
nginx

# Start the internal MinerU API on port 8001
echo "[*] Booting internal MinerU API..."
exec mineru-api --host 127.0.0.1 --port 8001 --enable-vlm-preload true
