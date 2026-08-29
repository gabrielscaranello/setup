#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_add_vscodium_apt_repo() {
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

_add_vscodium_dnf_repo() {
  local repo_path="/etc/yum.repos.d/vscodium.repo"

  if [ -f "$repo_path" ]; then
    echo "VSCodium repository already configured on Fedora, skipping."
    return 0
  fi

  echo "Configuring VSCodium repository for DNF..."
  cat << 'EOF_REPO' | sudo tee "$repo_path" >/dev/null
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
EOF_REPO
}

_install_vscodium() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  apt)
    _add_vscodium_apt_repo
    install_packages codium
    ;;
  dnf)
    _add_vscodium_dnf_repo
    install_packages codium
    ;;
  pacman)
    echo "Installing Code (OSS) from Arch repositories..."
    install_packages code
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up VSCodium..."
  _install_vscodium
  echo "setup-vscodium complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
