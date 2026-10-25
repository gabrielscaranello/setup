FROM ubuntu:24.04

ARG BATS_VERSION=1.11.0

# Enable universe and multiverse on Ubuntu 24.04 base and configure APT optimizations
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && mkdir -p /etc/dpkg/dpkg.cfg.d \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/force-unsafe-io \
    && sed -i 's/Components: .*/Components: main universe restricted multiverse/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true \
    && printf 'Acquire::http::Pipeline-Depth "5";\nAcquire::Languages "none";\nBinary::apt::APT::Keep-Downloaded-Packages "true";\n' > /etc/apt/apt.conf.d/99optimizations \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        sudo curl wget git bash ca-certificates sqlite3 \
        python3 python3-pip zsh fzf ripgrep fd-find tar xz-utils unzip procps file gnupg \
    && rm -rf /var/lib/apt/lists/*

# Emulate Linux Mint os-release and APT preferences
RUN printf 'NAME="Linux Mint"\nVERSION="22.3 (Zena)"\nID=linuxmint\nID_LIKE="ubuntu debian"\nPLATFORM_ID="platform:mint22"\nVERSION_ID="22.3"\nVERSION_CODENAME=zena\nUBUNTU_CODENAME=noble\n' > /etc/os-release \
    && mkdir -p /etc/apt/preferences.d /etc/apt/sources.list.d /usr/share/keyrings /etc/dpkg/dpkg.cfg.d \
    && printf 'force-confdef\nforce-confold\n' > /etc/dpkg/dpkg.cfg.d/force-conf \
    && printf 'Dpkg::Options {\n  "--force-confdef";\n  "--force-confold";\n};\n' > /etc/apt/apt.conf.d/99force-conf \
    && printf 'Package: *\nPin: origin packages.linuxmint.com\nPin-Priority: 700\n' > /etc/apt/preferences.d/official-package-repositories.pref \
    && curl -sL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA6616109451BBBF2' | gpg --dearmor > /usr/share/keyrings/linuxmint-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/linuxmint-keyring.gpg] http://packages.linuxmint.com wilma main upstream import backport" > /etc/apt/sources.list.d/official-package-repositories.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends ubuntu-system-adjustments \
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
