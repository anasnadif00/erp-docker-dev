#!/bin/bash

COMMIT_MSG="$1"
ARG_CLIENT="$2"




# Get Windows username dynamically
USERNAME=$(whoami)
LOCAL_BASE="C:/Users/$USERNAME/erp-docker-dev/workspace"

git config --global user.name "$USERNAME"

# Use provided client or fallback to saved one
if [ -n "$ARG_CLIENT" ]; then
  CLIENT="$ARG_CLIENT"
else
  CLIENT=$(cat "$LOCAL_BASE/.current-client" 2>/dev/null)
fi

# Validate inputs
if [ -z "$CLIENT" ] || [ -z "$COMMIT_MSG" ]; then
  echo "❌ Usage: ./deploy-to-server.sh \"<commit message>\" [client-name]"
  echo "⛔ Make sure to run ./prepare-local.sh <client> first if no client is set"
  exit 1
fi

CLIENT_DIR="$LOCAL_BASE/$CLIENT"
cd "$CLIENT_DIR" || {
  echo "❌ Workspace not found: $CLIENT_DIR"
  exit 1
}

if [ ! -d .git ]; then
  echo "❌ Not a Git repository: $CLIENT_DIR"
  exit 1
fi

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet; then
  echo "⚠️  No changes to commit for $CLIENT"
else
  echo "📤 Committing changes for $CLIENT..."
  git add .
  git commit -m "$COMMIT_MSG" || {
    echo "❌ Git commit failed — probably nothing staged."
    exit 1
  }
fi

echo "🔄 Pulling latest changes from remote..."
git pull --rebase origin master || {
  echo "❌ Git pull failed"
  exit 1
}

echo "⬆️  Pushing to remote..."
git push || {
  echo "❌ Git push failed"
  exit 1
}


echo "✅ Deploy completed for '$CLIENT'"
