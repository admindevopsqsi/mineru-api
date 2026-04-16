#!/bin/bash
set -e

# Auto-detect RunPod persistent volume paths
if [ -d "/workspace" ]; then
    export STORAGE_DIR="/workspace"
elif [ -d "/runpod-volume" ]; then
    export STORAGE_DIR="/runpod-volume"
else
    # Fallback for local docker run if no volume is provided
    export STORAGE_DIR="/models"
    mkdir -p /models
fi

# Tell MinerU where the config should be
export MINERU_TOOLS_CONFIG_JSON="$STORAGE_DIR/mineru.json"
export MINERU_MODEL_SOURCE="local"

# Set HOME to the persistent storage.
# This ensures that when mineru-models-download runs, 
# it downloads directly into the mapped volume, and won't bloat the ephemeral container.
export HOME="$STORAGE_DIR"

if [ ! -f "$MINERU_TOOLS_CONFIG_JSON" ]; then
    echo "================================================================"
    echo "[!] mineru.json not found in $STORAGE_DIR."
    echo "[!] Starting MinerU Models Download..."
    echo "[!] This will take a while, but it will be saved to your network volume."
    echo "================================================================"
    
    mineru-models-download -s huggingface -m all
    
    echo "================================================================"
    echo "[*] Download complete!"
    echo "================================================================"
else
    echo "[*] MinerU models configuration found in $STORAGE_DIR. Skipping download."
fi

echo "[*] Executing command: $@"
exec "$@"
