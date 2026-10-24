ARG OPENSUSE_VERSION=16.1
FROM opensuse/leap:${OPENSUSE_VERSION}

ARG BATS_VERSION=1.11.0

# Configure Zypp caching optimizations and install base tools
RUN sed -i 's/^# keeppackages = 0/keeppackages = 1/' /etc/zypp/zypp.conf 2>/dev/null || true \
    && zypper --non-interactive refresh \
    && zypper --non-interactive install -y --no-recommends \
        sudo curl wget git bash ca-certificates sqlite3 shadow \
        python3 python3-pip zsh fzf ripgrep fd tar xz unzip procps file \
    && zypper clean --all

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
