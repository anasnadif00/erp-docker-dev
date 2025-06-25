#!/bin/bash

# === Setup iniziale ===
CLIENT="$1"
SERVER_USER="anadif"
SERVER_HOST="svi2021.magia3.it"
USERNAME=$(whoami)

# Percorsi server
DEFAULT_SERVER_BASE="/data/cube_test"
VERSION_ONLY_BASE="/data/cube_test"

# Percorsi locali (Linux path)
LOCAL_BASE="/mnt/c/Users/$USERNAME/erp-docker-dev/workspace"
WORKSPACE="$LOCAL_BASE/$CLIENT"

# === Validazione input ===
if [ -z "$CLIENT" ]; then
  echo "❌ Usage: ./prepare-local.sh <client-name>"
  exit 1
fi

# Salvataggio client corrente
mkdir -p "$LOCAL_BASE"
echo "$CLIENT" > "$LOCAL_BASE/.current-client"

echo "🛠️ Preparing workspace at: $WORKSPACE"
mkdir -p "$WORKSPACE"

# === Step 1: Clona dal bare repo ===
echo "📦 Cloning clean committed files from bare repo on server..."
GIT_REPO_PATH="$DEFAULT_SERVER_BASE/.${CLIENT}.git"

git clone "ssh://$SERVER_USER@$SERVER_HOST$GIT_REPO_PATH" "$WORKSPACE"
if [ $? -ne 0 ]; then
  echo "❌ Git clone failed. Check repo path or remote state."
  exit 1
fi

# === Step 2: Determina e copia ERP binaries ===
echo "🔍 Determining ERP binary version on server..."

if [ "$CLIENT" == "2.3.1" ]; then
  BIN_PATH=$(ssh "$SERVER_USER@$SERVER_HOST" \
    "[ -d '$VERSION_ONLY_BASE/2.3.1/bin' ] && echo '$VERSION_ONLY_BASE/2.3.1/bin' || echo '$VERSION_ONLY_BASE/2.3.0/bin'")
  TASKS_PATH="$VERSION_ONLY_BASE/2.3.1/src/build/tasks"
  CLASSES9I_PATH="$VERSION_ONLY_BASE/2.3.1/src/classes9i"
else
  BIN_PATH=$(ssh "$SERVER_USER@$SERVER_HOST" \
    "[ -d '$DEFAULT_SERVER_BASE/$CLIENT/2.3.1/bin' ] && echo '$DEFAULT_SERVER_BASE/$CLIENT/2.3.1/bin' || echo '$DEFAULT_SERVER_BASE/$CLIENT/2.3.0/bin'")
  TASKS_PATH="$VERSION_ONLY_BASE/2.3.1/src/build/tasks"
  CLASSES9I_PATH="$VERSION_ONLY_BASE/2.3.1/src/classes9i"
fi

# === Step 3: Copia cartella tasks ===
# echo "📂 Copying build tasks from: $TASKS_PATH"
# mkdir -p "$WORKSPACE/src/build/"
# scp -r "$SERVER_USER@$SERVER_HOST:$TASKS_PATH" "$WORKSPACE/src/build/"

# === Step 4: Flatten cartella Tasks/ se esiste ===
if [ -d "$WORKSPACE/src/build/tasks/Tasks" ]; then
  echo "⚙️ Flattening nested Tasks/ directory..."
  mv "$WORKSPACE/src/build/tasks/Tasks/"* "$WORKSPACE/src/build/tasks/"
  rmdir "$WORKSPACE/src/build/tasks/Tasks"
fi

# === Step 5: Copia classes9i ===
# echo "📂 Copying shared classes9i from: $CLASSES9I_PATH"
# mkdir -p "$WORKSPACE/2.3.1/src/classes9i"
# scp -r "$SERVER_USER@$SERVER_HOST:$CLASSES9I_PATH/" "$WORKSPACE/2.3.1/src/"

# === Done ===
echo "✅ All required tasks, classes9i, and binaries downloaded."
echo "✅ Workspace for '$CLIENT' is ready at: $WORKSPACE"
