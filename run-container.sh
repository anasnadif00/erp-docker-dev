#!/bin/bash

# 1⃣⃣ Parametro: nome del client
ARG_CLIENT="$1"

# 2⃣⃣ User + rilevamento ambiente
USERNAME="anasn"

if grep -qi microsoft /proc/version 2>/dev/null; then
  ENV_TYPE="WSL"
  LOCAL_BASE="C:/Users/$USERNAME/erp-docker-dev/workspace"
elif type cygpath >/dev/null 2>&1; then
  ENV_TYPE="MobaXterm/GitBash"
  LOCAL_BASE="C:/Users/$USERNAME/erp-docker-dev/workspace"
else
  echo "❌ Ambiente non supportato."
  exit 1
fi

# 3⃣⃣ Client da parametro o file .current-client
if [ -n "$ARG_CLIENT" ]; then
  CLIENT="$ARG_CLIENT"
else
  CLIENT=$(cat "$LOCAL_BASE/.current-client" 2>/dev/null)
fi

if [ -z "$CLIENT" ]; then
  echo "❌ Nessun client specificato e nessun .current-client trovato."
  echo "Usage: ./run-container.sh [client-name]"
  exit 1
fi

CLIENT_DIR="$LOCAL_BASE/$CLIENT"

if [ ! -d "$CLIENT_DIR" ]; then
  echo "❌ Directory del client non trovata: $CLIENT_DIR"
  exit 1
fi

if [ ! -f Dockerfile ]; then
  echo "❌ Dockerfile non trovato nella directory corrente: $(pwd)"
  exit 1
fi

# 4⃣⃣ Traduci path C:/... -> C:/... per Docker
if [[ "$CLIENT_DIR" == C:/* ]]; then
  CLIENT_DIR="C:/${CLIENT_DIR#C:/}"
fi

# 5⃣⃣ Docker paths
CONTEXT_PATH="$CLIENT_DIR"
MOUNT_PATH="$CLIENT_DIR"

echo "🐳 Costruzione dell'immagine Docker per il client '$CLIENT'..."
echo "📁 Context: $CONTEXT_PATH"
echo "📁 Mount: $MOUNT_PATH"

# Path assoluto al Dockerfile
DOCKERFILE_PATH="C:/Users/$USERNAME/erp-docker-dev/Dockerfile"

docker build -t erp-bc4j-$CLIENT -f "$DOCKERFILE_PATH" "$CONTEXT_PATH"
if [ $? -ne 0 ]; then
  echo "❌ Docker build fallito."
  exit 1
fi

# 🚹 Rimuove container precedente se esiste
docker rm -f dev-$CLIENT 2>/dev/null

echo "🚀 Avvio del container..."
docker run -dit --name dev-$CLIENT \
  -v "$MOUNT_PATH:/app/$CLIENT" \
  -v "$LOCAL_BASE/2.3.1/bin:/data/cube/2.3.1/bin" \
  -v "$LOCAL_BASE/2.3.1/src/build:/data/cube/2.3.1/src/build" \
  erp-bc4j-$CLIENT sleep infinity

if [ $? -ne 0 ]; then
  echo "❌ Fallito l'avvio del container."
  exit 1
fi

# 🔗 Symlink e cartelle nel container
docker exec dev-$CLIENT bash -c "
  echo '🔗 Creazione symlink /data/cube -> /app'
  ln -sfn /app /data/cube

  echo '📁 Creazione cartelle per output e build'
  mkdir -p /data/deploy/ant2
  mkdir -p /app/$CLIENT/build
  ln -sfn /app/$CLIENT/build /data/deploy/ant2/classes.$USERNAME

  echo '📁 Setup struttura client'
  mkdir -p /data/cube/$CLIENT
  ln -sfn /app/$CLIENT/src /data/cube/$CLIENT/src
  ln -sfn /app/$CLIENT/2.3.1 /data/cube/$CLIENT/2.3.1

  ln -sfn /app/$CLIENT/2.3.1/src/classes9i /data/cube/2.3.1/src/classes9i
"

# 📦 Compila brutalcopy.jar e copia in posizione accessibile
# NOTA: apache-ant-1.7.0 è un jar, quindi non è una cartella. Salviamo altrove.
echo "📦 Compilazione di brutalcopy.jar e copia in /data/cube/2.3.1/lib..."
docker exec dev-$CLIENT bash -c "
  mkdir -p /data/cube/2.3.1/lib && \
  cd /data/cube/2.3.1/src/build/tasks/classes && \
  jar cf brutalcopy.jar it/dataconsult/ant/task/*.class it/dataconsult/ant/types/*.class && \
  cp brutalcopy.jar /data/cube/2.3.1/lib/
"

echo "✅ Container 'dev-$CLIENT' avviato e pronto!"