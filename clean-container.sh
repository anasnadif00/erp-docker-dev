#!/bin/bash

CLIENTE="$1"

# Get Windows username dynamically
USERNAME="anasn"
LOCAL_BASE="C:/Users/$USERNAME/erp-docker-dev/workspace"
CLIENT_DIR="$LOCAL_BASE/$CLIENTE"
CURRENT_CLIENT_FILE="$LOCAL_BASE/.current-client"

if [ -z "$CLIENTE" ]; then
  echo "Usage: ./clean-container.sh <client-name>"
  exit 1
fi

echo "🗑️ Removing Docker container for $CLIENTE..."
docker rm -f dev-$CLIENTE 2>/dev/null || echo "ℹ️  No container to remove"

echo "🧼 Removing Docker image for $CLIENTE..."
docker rmi erp-bc4j-$CLIENTE 2>/dev/null || echo "ℹ️  No image to remove"

echo "🧹 Deleting local workspace folder: $CLIENT_DIR"
rm -rf "$CLIENT_DIR"

if [ -f "$CURRENT_CLIENT_FILE" ]; then
  CURRENT=$(cat "$CURRENT_CLIENT_FILE")
  if [ "$CURRENT" = "$CLIENTE" ]; then
    echo "🧽 Removing .current-client (was pointing to $CLIENTE)"
    rm -f "$CURRENT_CLIENT_FILE"
  fi
fi

echo "✅ Cleaned everything related to '$CLIENTE'"
