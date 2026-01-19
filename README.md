# 🤖 Claude Code CLI Container Image

## ✨ Intention and Overview

This repository provides a **ready-to-use Docker image** encapsulating the Claude Code Command Line Interface (CLI). The primary intention is to establish a **consistent, isolated, and portable environment** for interacting with the Gemini API.

Using this container image allows you to:

- **Avoid Local Dependency Hassle:** Run the Claude-Code CLI and all dependencies directly on your host machine.
- **Ensure Version Consistency:** Lock in a specific, tested version of the Claude CLI, guaranteeing reproducible results across different projects and environments.
- **Simplify Setup:** Get up and running with a single `podman run` command, ideal for rapid prototyping, CI/CD pipelines, and project baselines.
- **Manage API Key Securely:** Easily pass your sensitive **GEMINI_API_KEY** to the container using standard Docker environment variables.

---

## 🚀 Quick Start

Follow these steps to quickly execute Claude CLI commands using the Docker image.

### 1. Build the container image

You must have **Podman** installed on your system.

```bash
podman build -t [YOUR_CONTAINER_IMAGE_NAME]
```

### 2. Run the CLI Command

Use the following command structure to execute any Claude CLI command inside the container.

```bash
 podman run -it --rm \
    --name [YOUR_CONTAINER_NAME] \
    --userns=keep-id:uid=1000,gid=1000 \
    -v "$(pwd):/workspace:Z" \
    [YOUR_CONTAINER_IMAGE_NAME] /bin/zsh

```
