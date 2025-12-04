# Base image - standard Ubuntu
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools and create bence user
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        openssh-client \
        git \
        jq \
        sudo \
        bash \
    && groupadd --gid 1000 bence \
    && useradd --uid 1000 --gid bence --shell /bin/bash --create-home bence \
    && echo bence ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/bence \
    && chmod 0440 /etc/sudoers.d/bence \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends google-cloud-cli \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Ensure SSH directory exists with correct permissions
RUN mkdir -p /home/bence/.ssh/vms \
    && chown -R bence:bence /home/bence/.ssh \
    && chmod 700 /home/bence/.ssh \
    && chmod 600 /home/bence/.ssh/* 2>/dev/null || true

# Switch to bence user
USER bence

# Set working directory
WORKDIR /workspaces/workflow

