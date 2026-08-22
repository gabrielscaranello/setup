FROM debian:trixie

ARG BATS_VERSION=1.11.0

# Install base tools
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        sudo curl wget git bash ca-certificates kcov \
    && rm -rf /var/lib/apt/lists/*

# Install bats-core from source for a consistent version across all distros
RUN git clone --depth 1 --branch "v${BATS_VERSION}" \
    https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

# Create non-root user with passwordless sudo
RUN useradd -m -s /bin/bash gabriel \
    && echo 'gabriel ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers

WORKDIR /setup
COPY . .
RUN chown -R gabriel:gabriel /setup

USER gabriel
