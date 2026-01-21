FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    jq \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for accessing host Docker daemon)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install k3s
RUN curl -sfL https://get.k3s.io | sh -

# Install kubectl (should come with k3s, but ensure it's available)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install additional useful tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    less \
    tmux \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Add kubectl completion
RUN kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null

WORKDIR /workspace
