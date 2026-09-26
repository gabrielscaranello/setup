#!/bin/bash

# LMDE-specific repository helper functions (sourced as utility, not executed directly)
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || source "scripts/_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/../debian/_repositories.sh" 2> /dev/null || source "scripts/system/debian/_repositories.sh" 2> /dev/null || true

get_lmde_codename() {
  local os_release_file="${OS_RELEASE_PATH:-/etc/os-release}"
  if [ -f "$os_release_file" ]; then
    local version_codename
    version_codename="$(grep '^VERSION_CODENAME=' "$os_release_file" 2> /dev/null | cut -d= -f2 | tr -d '"'\'' ' || true)"
    if [ -n "$version_codename" ]; then
      echo "$version_codename"
      return 0
    fi
  fi

  if [ -f /etc/linuxmint/info ]; then
    local mint_codename
    mint_codename="$(grep '^CODENAME=' /etc/linuxmint/info 2> /dev/null | cut -d= -f2 | tr -d '"'\'' ' || true)"
    if [ -n "$mint_codename" ]; then
      echo "$mint_codename"
      return 0
    fi
  fi

  echo "gigi"
}

get_lmde_debian_codename() {
  local os_release_file="${OS_RELEASE_PATH:-/etc/os-release}"
  if [ -f "$os_release_file" ]; then
    local debian_codename
    debian_codename="$(grep '^DEBIAN_CODENAME=' "$os_release_file" 2> /dev/null | cut -d= -f2 | tr -d '"'\'' ' || true)"
    if [ -n "$debian_codename" ]; then
      echo "$debian_codename"
      return 0
    fi
  fi

  get_debian_codename
}

_is_lmde_official_repo_configured() {
  local sources_list="${APT_SOURCES_LIST:-/etc/apt/sources.list}"
  local sources_d="${APT_SOURCES_D:-/etc/apt/sources.list.d}"

  if [ -f "$sources_list" ] && grep -Eq "^deb[[:space:]]+.*packages\.linuxmint\.com" "$sources_list" 2> /dev/null; then
    return 0
  fi

  if [ -d "$sources_d" ] && grep -Erq "^deb[[:space:]]+.*packages\.linuxmint\.com" "$sources_d" 2> /dev/null; then
    return 0
  fi

  return 1
}

add_lmde_official_repo() {
  local codename
  codename="$(get_lmde_codename)"
  local mint_sources_file="${APT_MINT_SOURCES:-/etc/apt/sources.list.d/mint.list}"

  if _is_lmde_official_repo_configured; then
    echo "Linux Mint official repository is already configured, skipping."
    return 0
  fi

  echo "Configuring Linux Mint repository for codename '${codename}'..."
  sudo mkdir -p "$(dirname "$mint_sources_file")"

  if ! dpkg -s linuxmint-keyring > /dev/null 2>&1; then
    echo "Ensuring linuxmint-keyring is installed..."
    local keyring_tmp="/tmp/linuxmint-keyring.deb"
    download_file "http://packages.linuxmint.com/pool/main/l/linuxmint-keyring/linuxmint-keyring_2022.06.21_all.deb" "$keyring_tmp" || true
    if [ -f "$keyring_tmp" ]; then
      sudo apt-get install -y --no-install-recommends "$keyring_tmp" 2> /dev/null || sudo dpkg -i "$keyring_tmp" 2> /dev/null || true
      rm -f "$keyring_tmp"
    fi
  fi

  cat << EOF | sudo tee "$mint_sources_file" > /dev/null
deb http://packages.linuxmint.com ${codename} main upstream import backport
EOF

  echo "Updating APT package cache for Linux Mint..."
  sudo apt update -qq
}

add_lmde_backports_repo() {
  local debian_codename
  debian_codename="$(get_lmde_debian_codename)"
  local backports_file="${APT_BACKPORTS_FILE:-/etc/apt/sources.list.d/backports.list}"

  if _is_debian_backports_configured "$debian_codename"; then
    echo "Debian backports repository (${debian_codename}-backports) is already configured, skipping."
    return 0
  fi

  echo "Configuring Debian backports repository for codename '${debian_codename}'..."
  sudo mkdir -p "$(dirname "$backports_file")"
  cat << EOF | sudo tee "$backports_file" > /dev/null
deb http://deb.debian.org/debian ${debian_codename}-backports main contrib non-free non-free-firmware
EOF

  echo "Updating APT package cache for Debian backports..."
  sudo apt update -qq
}
