ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}

ARG BATS_VERSION=1.11.0

# Configure APT performance, pipelining, and package caching optimizations
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && mkdir -p /etc/dpkg/dpkg.cfg.d \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/force-unsafe-io \
    && printf 'Acquire::http::Pipeline-Depth "5";\nAcquire::Languages "none";\nBinary::apt::APT::Keep-Downloaded-Packages "true";\n' > /etc/apt/apt.conf.d/99optimizations \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        sudo curl wget git bash ca-certificates kcov sqlite3 \
        python3 python3-pip zsh fzf ripgrep fd-find tar xz-utils unzip procps file gnupg \
    && rm -rf /var/lib/apt/lists/*

# Emulate LMDE 7 (Gigi) os-release, APT preferences and Linux Mint repositories
RUN printf 'NAME="LMDE"\nVERSION="7 (gigi)"\nID=linuxmint\nID_LIKE=debian\nPLATFORM_ID="platform:lmde7"\nVERSION_ID="7"\nVERSION_CODENAME=gigi\nDEBIAN_CODENAME=trixie\n' > /etc/os-release \
    && mkdir -p /etc/apt/preferences.d /etc/apt/sources.list.d /usr/share/keyrings /etc/dpkg/dpkg.cfg.d \
    && printf 'force-confdef\nforce-confold\n' > /etc/dpkg/dpkg.cfg.d/force-conf \
    && printf 'Dpkg::Options {\n  "--force-confdef";\n  "--force-confold";\n};\n' > /etc/apt/apt.conf.d/99force-conf \
    && printf 'Package: *\nPin: origin packages.linuxmint.com\nPin-Priority: 700\n' > /etc/apt/preferences.d/official-package-repositories.pref \
    && curl -sL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA6616109451BBBF2' | gpg --dearmor > /usr/share/keyrings/linuxmint-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/linuxmint-keyring.gpg] http://packages.linuxmint.com gigi main upstream import backport" > /etc/apt/sources.list.d/official-package-repositories.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends debian-system-adjustments 2>/dev/null || true \
    && rm -rf /var/lib/apt/lists/*

# Install bats-core from source for a consistent version across all distros
RUN git clone --depth 1 --branch "v${BATS_VERSION}" \
    https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

ARG USERNAME=setupuser

# Create non-root user with passwordless sudo
RUN useradd -m -s /bin/bash "$USERNAME" \
    && echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers \
    && sed -i 's|secure_path=".*"|secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"|' /etc/sudoers

WORKDIR /setup

USER ${USERNAME}
