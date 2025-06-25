# erp-docker-dev
A docker-based development environment to manage, build, run and deploy a java application.
# 🐳 ERP Docker Dev Environment

A Docker-powered development environment manager for handling **multiple client-specific personalizations** of a Java appliation. Each client has its own fork of the core ERP codebase, stored as  Git repositories on a remote SSH-accessible server**.

Preferably run it using MobaXTerm.

In this specific case the java application consist of a ERP Software written in java that requires apache-ant-1.7.0 for compiling its code.

This toolset simplifies the process of:
- Cloning ERP source code for a specific client
- Building and running the ERP app inside Docker
- Managing per-client workspaces
- Committing and pushing changes back to the server

---

## 📦 Features

- 🔁 Supports **multiple parallel ERP client versions**
- 🐳 Docker-based: runs on Windows (via WSL/Git Bash) or Linux
- 🔐 Uses **SSH** to clone from remote server-hosted bare Git repos
- 🧰 Handles build requirements (Java 8, Ant 1.7.0, legacy layout) -> You can change these based on your application needs.
- 🧼 Includes scripts to prepare, build, run, clean, and deploy
- 🧪 Build logs and run logs are automatically saved

---

## 💡 Use Case

You maintain or develop custom versions of the same java application for different clients. This repo lets you easily:
- Spin up an isolated environment for each client
- Compile and test their version inside Docker
- Deploy changes back to a centralized server

---
## 📜 Script Overview

| Script               | Purpose                                           |
|----------------------|---------------------------------------------------|
| `prepare-local.sh`   | Clones the repo from server + sets up workspace   |
| `run-container.sh`   | Builds and starts Docker container for the client |
| `build.sh`           | Builds the ERP app inside the container           |
| `run.sh`             | Runs the ERP binary (e.g., GUI) inside container  |
|                      | uses X Server to be able to display the GUI       |
|                      | (that's why its recommended to use MobaXTerm)     |
| `deploy-to-server.sh`| Git add/commit/push to server repo                |
| `clean-container.sh` | Removes container, image, workspace               |
| `.current-client`    | Helper file to remember active client version     |

## 🧱 Folder Structure

erp-docker-dev/
├── Dockerfile # Java 8 + Ant image for legacy ERP builds (In this case)
├── workspace/ # Client-specific working directories
│ └── .current-client # Tracks currently active client
├──  `prepare-local.sh`
├──  `run-container.sh`
├──  `build.sh`
├──  `run.sh`
├──  `deploy-to-server.sh`
├──  `clean-container.sh`
├──   Dockerfile
├── .gitignore
└── README.md
