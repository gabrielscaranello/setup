FROM archlinux:latest

ARG BATS_VERSION=1.11.0

# Configure Pacman performance optimizations and install base tools
RUN sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf \
    && pacman -Sy --noconfirm \
        sudo curl wget git kcov sqlite \
        python python-pip zsh fzf ripgrep fd tar xz unzip procps-ng file \
    && pacman -Sc --noconfirm

# Install bats-core from source for a consistent version across all distros
RUN git clone --depth 1 --branch "v${BATS_VERSION}" \
    https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

ARG USERNAME=setupuser

# Create non-root user with passwordless sudo
RUN useradd -m -s /bin/bash "$USERNAME" \
    && echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

WORKDIR /setup

USER ${USERNAME}
