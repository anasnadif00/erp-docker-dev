#!/bin/bash

# === Grab parameters ===
ARG1="$1"
ARG2="$2"

USERNAME=$(whoami)
LOCAL_BASE="/drives/c/Users/$USERNAME/erp-docker-dev/workspace"
CURRENT_CLIENT=$(cat "$LOCAL_BASE/.current-client" 2>/dev/null)

# === Validate .current-client ===
if [ -z "$CURRENT_CLIENT" ]; then
  echo "❌ No .current-client found. Please specify a client."
  exit 1
fi

# === Determine client & build-arg based on param count ===
if [ -n "$ARG2" ]; then
  # 2 params: 1st = build-arg, 2nd = client
  BUILD_ARG="$ARG1"
  CLIENT="$ARG2"
  if [ "$CLIENT" != "2.3.1" ]; then
    echo "❌ Only client '2.3.1' supports build args. '$CLIENT' does not."
    exit 1
  fi
else
  # 1 param
  if [ "$CURRENT_CLIENT" == "2.3.1" ]; then
    # .current-client is 2.3.1 → treat param as build-arg
    BUILD_ARG="$ARG1"
    CLIENT="$CURRENT_CLIENT"
  else
    # .current-client is not 2.3.1 → treat param as client
    BUILD_ARG=""
    CLIENT="$ARG1"
  fi
fi

# === Final fallback ===
if [ -z "$CLIENT" ]; then
  CLIENT="$CURRENT_CLIENT"
fi

echo "🔍 Client: $CLIENT"
echo "🔍 Build-arg: ${BUILD_ARG:-<none>}"

# === Check if required 'src' directory exists in local workspace ===
SRC_DIR="$LOCAL_BASE/$CLIENT/src"
if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Missing directory: $SRC_DIR"
  echo "🔍 Please check your workspace structure."
  exit 1
fi

# === Determine build script path inside Docker ===
if [ "$CLIENT" = "2.3.1" ]; then
  BUILD_SCRIPT="/app/$CLIENT/src/build/compila.sh"
else
  BUILD_SCRIPT="/app/$CLIENT/src/ant/compila.sh"
fi

# === Validate build script inside Docker ===
echo "🔍 Checking workspace inside Docker container..."
docker exec "dev-$CLIENT" test -f "$BUILD_SCRIPT"
if [ $? -ne 0 ]; then
  echo "❌ Build script not found inside container: $BUILD_SCRIPT"
  echo "🔍 Ensure the container was started with the correct workspace mounted."
  exit 1
fi

# === Build log file ===
LOG_FILE="$LOCAL_BASE/$CLIENT/build.log"
echo "📄 Logging to: $LOG_FILE"

# === Create missing /data/cube/$CLIENT/src symlink in the container ===
docker exec "dev-$CLIENT" bash -c "
  if [ ! -d /data/cube/$CLIENT/src ]; then
    echo '🔧 Creating symlink: /data/cube/$CLIENT/src -> /app/$CLIENT/src'
    mkdir -p /data/cube/$CLIENT
    ln -s /app/$CLIENT/src /data/cube/$CLIENT/src
  fi
"

# === Execute build script inside container ===
if [ -n "$BUILD_ARG" ]; then
  echo "▶️ Running inside container: $BUILD_SCRIPT $BUILD_ARG" > "$LOG_FILE"
  docker exec "dev-$CLIENT" bash -c "
    cd /app/$CLIENT/src/ant && \
    bash compila.sh '$BUILD_ARG'
  " | tee -a "$LOG_FILE"
else
  echo "▶️ Running inside container: $BUILD_SCRIPT" > "$LOG_FILE"
  docker exec "dev-$CLIENT" bash -c "
    cd /app/$CLIENT/src/ant && \
    bash compila.sh
  " | tee -a "$LOG_FILE"
fi

BUILD_RESULT=${PIPESTATUS[0]}

if [ $BUILD_RESULT -ne 0 ]; then
  echo "❌ Build failed with exit code $BUILD_RESULT"
  echo "🔍 Check the log: $LOG_FILE"
  exit $BUILD_RESULT
fi

# === Check if the build output directory exists ===
BUILD_OUTPUT_DIR="$LOCAL_BASE/$CLIENT/build"
if [ -d "$BUILD_OUTPUT_DIR" ]; then
  echo "📂 Opening build output folder..."
  explorer.exe "$BUILD_OUTPUT_DIR" 2>/dev/null
fi

echo "✅ Build complete for '$CLIENT'"
