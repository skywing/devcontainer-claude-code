# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set python version as build argument for easy updates
ARG PYTHON_VERSION=3.12

# Set environment variable to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 
# ========== install system dependencies ==========
#
RUN apt-get update && apt-get install -y \
  software-properties-common \
  && add-apt-repository ppa:deadsnakes/ppa \
  && apt-get update \
  && apt-get install -y \
  python${PYTHON_VERSION} \
  python${PYTHON_VERSION}-venv \
  git \
  curl \
  build-essential \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \ 
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python

# ========== install pip correctly for python 3.12 ==========
#
# user python's build-in 'ensurepip' to boostrap a compatible pip
RUN python3 -m ensurepip --upgrade && \
    python3 -m pip install --upgrade pip setuptools wheel
    


# ========== install node.js v25 ==========
#
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

# ========== Create a Non-Root user for security =========
#
# create a new user 'aidev' with user ID 1000
RUN groupadd --gid 1000 aidev && \
    useradd --uid 1000 --gid 1000 -m aidev && \
    apt-get update && apt-get install -y sudo && \
    usermod -aG sudo aidev && \
    echo "aidev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aidev

# Switch to the non-root user
USER aidev

#
# ========== Install python libraries ==========
#
# Set the working directory for the project
WORKDIR /home/aidev/workspace

# Copy the python requirements file into container
COPY --chown=aidev:aidev requirements.txt .

# Upgrade pip and install the python packages
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

ENV PATH /home/aidev/.local/bin:$PATH

# Keep the container running for the dev container to attach to
# CMD ["sleep", "infinity"]

