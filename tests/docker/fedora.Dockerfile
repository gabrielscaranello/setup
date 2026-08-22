FROM fedora:44

ARG BATS_VERSION=1.11.0

# Install base tools
RUN dnf install -y sudo curl wget git bash ca-certificates kcov \
    && dnf clean all

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
COPY --chown=${USERNAME}:${USERNAME} . .

USER ${USERNAME}
