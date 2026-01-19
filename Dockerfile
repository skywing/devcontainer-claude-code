# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set python version as build argument for easy updates
ARG PYTHON_VERSION=3.12
ARG TZ
ENV TZ="$TZ"

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
  gh \
  curl \
  wget \
  less \
  procps \
  sudo \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  neovim \
  fd-find \
  build-essential \
  language-pack-en \
  postgresql \
  postgresql-contrib \
  && apt-get clean && rm -rf /var/lib/apt/lists/*


RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \ 
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python

# ========== install pip correctly for python 3.12 ==========
#
# user python's build-in 'ensurepip' to boostrap a compatible pip
RUN python3 -m ensurepip --upgrade && \
    python3 -m pip install --upgrade pip setuptools wheel
    
# ========== Create a Non-Root user for security =========
# create a new user 'aidev' with user ID 1000
RUN groupadd --gid 1000 aidev && \
    useradd --uid 1000 --gid aidev --shell /bin/bash --create-home aidev && \
    usermod -aG sudo aidev && \
    echo "aidev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aidev


# ========== install node.js v25 ==========
#
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/npm-global && \
    chown -R aidev:aidev /usr/local/share


# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R aidev:aidev /commandhistory

# create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/aidev/.claude && \
  chown -R aidev:aidev /workspace /home/aidev/.claude

# Set the working directory for the project
WORKDIR /workspace

# Intall git delta
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Switch to the non-root user
USER aidev

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh
ENV SHELL=/bin/zsh

# set the default editor to neovim
ENV EDITOR=neovim
ENV VISUAL=neovim

# Install FZF from github instead of using ubuntu older version that doesn't support tmux and other options.
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
RUN ~/.fzf/install --all
ENV FZF_DEFAULT_OPTS='--height 40% --style full --preview "fzf-preview.sh {}" --bind "focus:transform-header:file --brief {}"'

# Installing ZSH for container and configure powerline10k 
ARG ZSH_IN_DOCKER_VERSION=1.2.1
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -p github \
  -p gh \
  -p node \
  -p npm \
  -p pip \
  -p postgres \
  -p python \
  -p copyfile \
  -p copypath \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# ========== install bun ===================
RUN curl -fsSL https://bun.com/install | bash  
ENV PATH="/home/aidev/.bun/bin:$PATH"

# Install Claude
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV ENABLE_LSP_TOOL=1

# Install Playwright with Chromium headless browswer
RUN bun install playwright
RUN bunx playwright install --with-deps --only-shell chromium
#
# ========== Install python libraries ==========
#

# Copy the python requirements file into container
COPY --chown=aidev:aidev requirements.txt .

# Upgrade pip and install the python packages
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

ENV PATH=/home/aidev/.local/bin:$PATH

USER aidev
# Keep the container running for the dev container to attach to
# CMD ["sleep", "infinity"]

