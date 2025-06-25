#!/bin/bash

# --- Parametri e setup ---
ARG_CLIENT="$1"
USERNAME="anasn"
LOCAL_BASE="C:/Users/$USERNAME/erp-docker-dev/workspace"

if [ -n "$ARG_CLIENT" ]; then
  CLIENT="$ARG_CLIENT"
else
  CLIENT=$(cat "$LOCAL_BASE/.current-client" 2>/dev/null)
fi

if [ -z "$CLIENT" ]; then
  echo "❌ No client specified and no .current-client found."
  echo "Usage: ./run.sh [client-name]"
  exit 1
fi

CLIENT_BASE="$LOCAL_BASE/$CLIENT"
CONTAINER_NAME="dev-$CLIENT"

# --- Verifica container in esecuzione ---
if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "❌ Docker container '$CONTAINER_NAME' is not running."
  echo "Try: ./run-container.sh $CLIENT"
  exit 1
fi

# --- Individua il binario Magia ---
MAGIA_231="$CLIENT_BASE/2.3.1/bin/Magia"
MAGIA_230="$CLIENT_BASE/2.3.0/bin/Magia"

echo "🔍 Checking for Magia binary at:"
echo "   1️⃣ $MAGIA_231"
echo "   2️⃣ $MAGIA_230"

if [ -x "$MAGIA_231" ]; then
  BIN_RELATIVE="2.3.1/bin/Magia"
  BIN_LINK="2.3.1"
elif [ -x "$MAGIA_230" ]; then
  BIN_RELATIVE="2.3.0/bin/Magia"
  BIN_LINK="2.3.0"
elif [ -f "$MAGIA_231" ] || [ -f "$MAGIA_230" ]; then
  echo "⚠️ Magia binary exists but is not executable."
  echo "Try this:"
  echo "chmod +x \"$MAGIA_231\" or \"$MAGIA_230\""
  exit 1
else
  echo "❌ No valid Magia binary found."
  exit 1
fi

MAGIA_DIR=$(dirname "$BIN_RELATIVE")
MAGIA_FILE=$(basename "$BIN_RELATIVE")
LOG_FILE="$CLIENT_BASE/run.log"

echo "📄 Logging to: $LOG_FILE"

# --- Symlink compatibilità: /app/2.3.x -> /app/$CLIENT/2.3.x ---
echo "🔗 Creating symlink inside container to match /app/$BIN_LINK --> /app/$CLIENT/$BIN_LINK..."
docker exec "$CONTAINER_NAME" ln -snf "/app/$CLIENT/$BIN_LINK" "/app/$BIN_LINK"

# --- Avvia Magia dentro il container ---
echo "🚀 Cleaning and launching Magia for '$CLIENT' inside Docker..."
docker exec -e DISPLAY=host.docker.internal:0 "$CONTAINER_NAME" bash -c "
  cd '/app/$MAGIA_DIR' && \
  echo '🧼 Cleaning Magia script and linuxvars...' && \
  tr -d '\r' < '$MAGIA_FILE' > .tmp && mv .tmp '$MAGIA_FILE' && \
  if [ -f ./etc/linuxvars ]; then \
    tr -d '\r' < './etc/linuxvars' > ./etc/.linuxvars_tmp && mv ./etc/.linuxvars_tmp ./etc/linuxvars; \
  fi && \
  chmod +x '$MAGIA_FILE' && \
  echo '🚀 Launching Magia...' && \
  ./'$MAGIA_FILE'
" | tee -a "$LOG_FILE"

MAGIA_RESULT=${PIPESTATUS[0]}

if [ $MAGIA_RESULT -ne 0 ]; then
  echo "❌ Magia exited with error code $MAGIA_RESULT"
  echo "📝 Check the log: $LOG_FILE"
  exit $MAGIA_RESULT
fi

echo "✅ Magia exited successfully."
