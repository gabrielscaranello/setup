FROM debian:trixie

ARG BATS_VERSION=1.11.0

# Install base tools and certificates
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        sudo curl wget git bash ca-certificates kcov sqlite3 gnupg gpg \
    && rm -rf /var/lib/apt/lists/*

# Configure LMDE repository and OS identity
RUN curl -fsSL http://packages.linuxmint.com/pool/main/l/linuxmint-keyring/linuxmint-keyring_2022.06.21_all.deb -o /tmp/linuxmint-keyring.deb \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends /tmp/linuxmint-keyring.deb \
    && rm -f /tmp/linuxmint-keyring.deb \
    && rm -rf /var/lib/apt/lists/* \
    && echo "deb http://packages.linuxmint.com gigi main upstream import backport" > /etc/apt/sources.list.d/mint.list \
    && printf '%s\n' \
        'PRETTY_NAME="LMDE 7 (gigi)"' \
        'NAME="LMDE"' \
        'VERSION_ID="7"' \
        'VERSION="7 (gigi)"' \
        'VERSION_CODENAME=gigi' \
        'ID=linuxmint' \
        'ID_LIKE=debian' \
        'DEBIAN_CODENAME=trixie' \
        'HOME_URL="https://www.linuxmint.com/"' \
        'SUPPORT_URL="https://forums.linuxmint.com/"' \
        'BUG_REPORT_URL="http://linuxmint-troubleshooting-guide.readthedocs.io/en/latest/"' \
        'PRIVACY_POLICY_URL="https://www.linuxmint.com/"' \
        > /etc/os-release \
    && mkdir -p /etc/linuxmint \
    && printf '%s\n' \
        'RELEASE=7' \
        'CODENAME=gigi' \
        'EDITION="Cinnamon"' \
        'DESCRIPTION="LMDE 7 (gigi)"' \
        'DESKTOP=Gnome' \
        'TOOLKIT=GTK' \
        > /etc/linuxmint/info

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
