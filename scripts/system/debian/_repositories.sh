#!/bin/bash

# Debian-specific repository helper functions (sourced as utility, not executed directly)

get_debian_codename() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    local debian_codename version_codename
    debian_codename="$(grep '^DEBIAN_CODENAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$debian_codename" ]; then
      echo "$debian_codename"
      return 0
    fi

    version_codename="$(grep '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$version_codename" ]; then
      echo "$version_codename"
      return 0
    fi
  fi

  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -cs 2>/dev/null && return 0
  fi

  # Fallback to trixie if detection fails
  echo "trixie"
}

_get_debian_codename() {
  get_debian_codename "$@"
}

_is_debian_backports_configured() {
  local codename="${1:-$(get_debian_codename)}"
  local sources_list="/etc/apt/sources.list"
  local sources_d="/etc/apt/sources.list.d"

  if [ -f "$sources_list" ] && grep -Eq "^deb[[:space:]]+.*[[:space:]]+${codename}-backports[[:space:]]+" "$sources_list" 2>/dev/null; then
    return 0
  fi

  if [ -d "$sources_d" ] && grep -Erq "^deb[[:space:]]+.*[[:space:]]+${codename}-backports[[:space:]]+" "$sources_d" 2>/dev/null; then
    return 0
  fi

  return 1
}

add_debian_backports_repo() {
  local codename
  codename="$(get_debian_codename)"
  local backports_file="/etc/apt/sources.list.d/backports.list"

  if _is_debian_backports_configured "$codename"; then
    echo "Debian backports repository (${codename}-backports) is already configured, skipping."
    return 0
  fi

  echo "Configuring Debian backports repository for codename '${codename}'..."
  sudo mkdir -p /etc/apt/sources.list.d
  sudo tee "$backports_file" >/dev/null <<EOF
deb http://deb.debian.org/debian ${codename}-backports main contrib non-free non-free-firmware
EOF

  echo "Updating APT package cache..."
  sudo apt update -qq
}

add_debian_vscodium_repo() {
  local keyring_path="/usr/share/keyrings/vscodium-archive-keyring.gpg"
  local sources_path="/etc/apt/sources.list.d/vscodium.sources"
  local gpg_key_url="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "VSCodium repository already configured on Debian, skipping."
    return 0
  fi

  echo "Configuring VSCodium repository for APT..."
  sudo install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d

  if command -v wget >/dev/null 2>&1; then
    wget -qO - "$gpg_key_url" | gpg --dearmor | sudo tee "$keyring_path" >/dev/null
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$gpg_key_url" | gpg --dearmor | sudo tee "$keyring_path" >/dev/null
  else
    echo "Error: Neither wget nor curl is available to download VSCodium GPG key" >&2
    return 1
  fi

  cat <<EOF_SOURCES | sudo tee "$sources_path" >/dev/null
Types: deb
URIs: https://download.vscodium.com/debs
Suites: vscodium
Components: main
Architectures: amd64 arm64
Signed-By: $keyring_path
EOF_SOURCES

  sudo apt update -qq
}

add_debian_mozilla_repo() {
  local keyring_path="/etc/apt/keyrings/packages.mozilla.org.asc"
  local sources_path="/etc/apt/sources.list.d/mozilla.sources"
  local repo_url="https://packages.mozilla.org/apt"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "Mozilla repository already configured, skipping."
    return 0
  fi

  echo "Configuring Mozilla repository for APT..."
  sudo install -d -m 0755 /etc/apt/keyrings

  if command -v wget >/dev/null 2>&1; then
    wget -q "${repo_url}/repo-signing-key.gpg" -O- | sudo tee "$keyring_path" >/dev/null
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "${repo_url}/repo-signing-key.gpg" | sudo tee "$keyring_path" >/dev/null
  else
    echo "Error: Neither wget nor curl is available to download Mozilla GPG key" >&2
    return 1
  fi

  cat <<EOF_SOURCES | sudo tee "$sources_path" >/dev/null
Types: deb
URIs: ${repo_url}
Suites: mozilla
Components: main
Signed-By: $keyring_path
EOF_SOURCES

  echo "Setting APT pinning priority for Mozilla repository..."
  cat <<EOF_PIN | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF_PIN

  sudo apt update -qq
}

add_debian_virtualbox_repo() {
  local keyring_path="/etc/apt/keyrings/oracle-virtualbox-2016.asc"
  local sources_path="/etc/apt/sources.list.d/virtualbox.sources"
  local gpg_key_url="https://www.virtualbox.org/download/oracle_vbox_2016.asc"
  local codename
  codename="$(get_debian_codename)"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "VirtualBox repository already configured on Debian, skipping."
    return 0
  fi

  echo "Configuring Oracle VirtualBox repository for APT..."
  sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d

  if command -v wget >/dev/null 2>&1; then
    wget -qO- "$gpg_key_url" | sudo tee "$keyring_path" >/dev/null
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$gpg_key_url" | sudo tee "$keyring_path" >/dev/null
  else
    echo "Error: Neither wget nor curl is available to download VirtualBox GPG key" >&2
    return 1
  fi

  cat <<EOF_SOURCES | sudo tee "$sources_path" >/dev/null
Types: deb
URIs: https://download.virtualbox.org/virtualbox/debian
Suites: ${codename}
Components: contrib
Architectures: amd64
Signed-By: $keyring_path
EOF_SOURCES

  sudo apt update -qq
}

add_debian_nonfree_repo() {
  local sources_list="${APT_SOURCES_LIST:-/etc/apt/sources.list}"
  local debian_sources="${APT_DEBIAN_SOURCES:-/etc/apt/sources.list.d/debian.sources}"

  echo "Ensuring Debian contrib, non-free, and non-free-firmware components are accessible..."
  if [ -f "$debian_sources" ]; then
    if ! grep -Eq "^Components:.*contrib" "$debian_sources" 2>/dev/null || ! grep -Eq "^Components:.*non-free-firmware" "$debian_sources" 2>/dev/null; then
      sudo sed -i '/^Components:/ s/$/ contrib non-free non-free-firmware/' "$debian_sources" 2>/dev/null || true
      sudo apt update -qq 2>/dev/null || true
    fi
  elif [ -f "$sources_list" ]; then
    if ! grep -Eq "^deb[[:space:]]+.*contrib" "$sources_list" 2>/dev/null || ! grep -Eq "^deb[[:space:]]+.*non-free-firmware" "$sources_list" 2>/dev/null; then
      sudo sed -i '/^deb[[:space:]]/ s/$/ contrib non-free non-free-firmware/' "$sources_list" 2>/dev/null || true
      sudo apt update -qq 2>/dev/null || true
    fi
  fi
}
