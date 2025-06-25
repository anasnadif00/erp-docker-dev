# Use OpenJDK 8 as base
FROM openjdk:8-jdk

# Install dependencies for GUI/Swing apps, build tools, and curl
RUN apt-get update && apt-get install -y \
  curl \
  tar \
  libxext6 \
  libxrender1 \
  libxtst6 \
  libxi6 \
  libxt6 \
  libxrandr2 \
  libgtk2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Create expected path for Magia to find Java
RUN mkdir -p /opt/jdk8/bin && \
    ln -s /usr/local/openjdk-8/bin/java /opt/jdk8/bin/java

# Download and extract Apache Ant 1.7.0
RUN mkdir -p /data/cube/2.3.1/src/build && \
    curl -sSL https://archive.apache.org/dist/ant/binaries/apache-ant-1.7.0-bin.tar.gz | \
    tar -xz -C /data/cube/2.3.1/src/build

# Create dummy colorize script for compila.sh
RUN echo -e '#!/bin/bash\ncat' > /data/cube/2.3.1/src/build/colorize && \
    chmod +x /data/cube/2.3.1/src/build/colorize

# Create expected Java location in /data/cube (used by legacy build scripts)
RUN mkdir -p /data/cube/2.3.1/src/build/jdk/bin && \
    ln -s /usr/local/openjdk-8/bin/java /data/cube/2.3.1/src/build/jdk/bin/java

# Prepare tasks lib directory in Ant (to be populated later by run-container.sh)
RUN mkdir -p /data/cube/2.3.1/src/build/apache-ant-1.7.0/lib/tasks

# Create missing /data/deploy/ant2/classes.root directory for build.xml
RUN mkdir -p /data/deploy/ant2/classes.root

# At runtime, /data/cube will be symlinked to /app
WORKDIR /app

# Default to interactive bash shell
CMD ["bash"]
