#!/bin/bash

# Optional client override
ARG_CLIENT="$1"

# Get Windows username dynamically
USERNAME=$(whoami)
LOCAL_BASE="/c/Users/$USERNAME/erp-docker-dev/workspace"

# Use passed client or fallback to .current-client
if [ -n "$ARG_CLIENT" ]; then
  CLIENT="$ARG_CLIENT"
else
  CLIENT=$(cat "$LOCAL_BASE/.current-client" 2>/dev/null)
fi

if [ -z "$CLIENT" ]; then
  echo "❌ No client specified and no .current-client found."
  echo "Usage: ./run-native.sh [client-name]"
  exit 1
fi

CLIENT_BASE="$LOCAL_BASE/$CLIENT"
MAGIA_231="$CLIENT_BASE/2.3.1/bin/Magia"
MAGIA_230="$CLIENT_BASE/2.3.0/bin/Magia"

echo "🔍 Checking for Magia binary locally..."
if [ -x "$MAGIA_231" ]; then
  MAGIA_PATH="$MAGIA_231"
elif [ -x "$MAGIA_230" ]; then
  MAGIA_PATH="$MAGIA_230"
elif [ -f "$MAGIA_231" ] || [ -f "$MAGIA_230" ]; then
  echo "⚠️ Magia script found but not executable. Running chmod +x..."
  chmod +x "$MAGIA_231" 2>/dev/null || chmod +x "$MAGIA_230"
  MAGIA_PATH="$MAGIA_231"
else
  echo "❌ Magia not found in either 2.3.1 or 2.3.0"
  exit 1
fi

echo "🧼 Cleaning Windows line endings..."
tr -d '\r' < "$MAGIA_PATH" > "$MAGIA_PATH.cleaned"
mv "$MAGIA_PATH.cleaned" "$MAGIA_PATH"
chmod +x "$MAGIA_PATH"

MAGIA_DIR=$(dirname "$MAGIA_PATH")
if [ -f "$MAGIA_DIR/etc/linuxvars" ]; then
  echo "🧼 Cleaning linuxvars..."
  tr -d '\r' < "$MAGIA_DIR/etc/linuxvars" > "$MAGIA_DIR/etc/linuxvars.tmp"
  mv "$MAGIA_DIR/etc/linuxvars.tmp" "$MAGIA_DIR/etc/linuxvars"
fi

# Create fake /opt/jdk8/bin/java that points to real java
FAKE_JAVA_UNIX="/c/opt/jdk8/bin/java"
FAKE_JAVA_WIN="C:\\opt\\jdk8\\bin\\java"

echo "🛠️ Creating fake /opt/jdk8/bin/java..."
mkdir -p "/c/opt/jdk8/bin"

cat << 'EOF' > "$FAKE_JAVA_UNIX"
#!/bin/bash
exec java "$@"
EOF

chmod +x "$FAKE_JAVA_UNIX"

echo "🚀 Launching Magia locally: $MAGIA_PATH"
"$MAGIA_PATH"
