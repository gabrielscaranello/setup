#!/bin/bash

# Debian-specific repository helper functions (sourced as utility, not executed directly)
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || source "scripts/_utils.sh" 2> /dev/null || true

get_debian_codename() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    local debian_codename version_codename
    debian_codename="$(grep '^DEBIAN_CODENAME=' /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$debian_codename" ]; then
      echo "$debian_codename"
      return 0
    fi

    version_codename="$(grep '^VERSION_CODENAME=' /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$version_codename" ]; then
      echo "$version_codename"
      return 0
    fi
  fi

  if command -v lsb_release > /dev/null 2>&1; then
    lsb_release -cs 2> /dev/null && return 0
  fi

  # Fallback to trixie if detection fails
  echo "trixie"
}

_is_debian_backports_configured() {
  local codename="${1:-$(get_debian_codename)}"
  local sources_list="/etc/apt/sources.list"
  local sources_d="/etc/apt/sources.list.d"

  if [ -f "$sources_list" ] && grep -Eq "^deb[[:space:]]+.*[[:space:]]+${codename}-backports[[:space:]]+" "$sources_list" 2> /dev/null; then
    return 0
  fi

  if [ -d "$sources_d" ] && grep -Erq "^deb[[:space:]]+.*[[:space:]]+${codename}-backports[[:space:]]+" "$sources_d" 2> /dev/null; then
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
  sudo tee "$backports_file" > /dev/null << EOF
deb http://deb.debian.org/debian ${codename}-backports main contrib non-free non-free-firmware
EOF

  echo "Updating APT package cache..."
  sudo apt update -qq
}

add_debian_vscodium_repo() {
  local keyring_path="${APT_VSCODIUM_KEYRING:-/usr/share/keyrings/vscodium-archive-keyring.gpg}"
  local sources_path="${APT_VSCODIUM_SOURCES:-/etc/apt/sources.list.d/vscodium.sources}"
  local gpg_key_url="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "VSCodium repository already configured on Debian, skipping."
    return 0
  fi

  echo "Configuring VSCodium repository for APT..."
  sudo install -d -m 0755 "$(dirname "$keyring_path")" "$(dirname "$sources_path")"

  if ! command -v gpg > /dev/null 2>&1; then
    echo "Installing gnupg for GPG keyring management..."
    sudo apt update -qq && sudo apt install -y gnupg 2> /dev/null || true
  fi

  fetch_url "$gpg_key_url" | gpg --dearmor | sudo tee "$keyring_path" > /dev/null

  cat << EOF_SOURCES | sudo tee "$sources_path" > /dev/null
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
  local keyring_path="${APT_MOZILLA_KEYRING:-/etc/apt/keyrings/packages.mozilla.org.asc}"
  local sources_path="${APT_MOZILLA_SOURCES:-/etc/apt/sources.list.d/mozilla.sources}"
  local preferences_path="${APT_MOZILLA_PREFERENCES:-/etc/apt/preferences.d/mozilla}"
  local repo_url="https://packages.mozilla.org/apt"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "Mozilla repository already configured, skipping."
    return 0
  fi

  echo "Configuring Mozilla repository for APT..."
  sudo install -d -m 0755 "$(dirname "$keyring_path")" "$(dirname "$sources_path")"

  fetch_url "${repo_url}/repo-signing-key.gpg" | sudo tee "$keyring_path" > /dev/null

  cat << EOF_SOURCES | sudo tee "$sources_path" > /dev/null
Types: deb
URIs: ${repo_url}
Suites: mozilla
Components: main
Signed-By: $keyring_path
EOF_SOURCES

  echo "Setting APT pinning priority for Mozilla repository..."
  sudo install -d -m 0755 "$(dirname "$preferences_path")"
  cat << EOF_PIN | sudo tee "$preferences_path" > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF_PIN

  sudo apt update -qq
}

add_debian_nonfree_repo() {
  local sources_list="${APT_SOURCES_LIST:-/etc/apt/sources.list}"
  local debian_sources="${APT_DEBIAN_SOURCES:-/etc/apt/sources.list.d/debian.sources}"

  echo "Ensuring Debian contrib, non-free, and non-free-firmware components are accessible..."
  if [ -f "$debian_sources" ]; then
    if ! grep -Eq "^Components:.*contrib" "$debian_sources" 2> /dev/null || ! grep -Eq "^Components:.*non-free-firmware" "$debian_sources" 2> /dev/null; then
      sudo sed -i '/^Components:/ s/$/ contrib non-free non-free-firmware/' "$debian_sources" 2> /dev/null || true
      sudo apt update -qq 2> /dev/null || true
    fi
  elif [ -f "$sources_list" ]; then
    if ! grep -Eq "^deb[[:space:]]+.*contrib" "$sources_list" 2> /dev/null || ! grep -Eq "^deb[[:space:]]+.*non-free-firmware" "$sources_list" 2> /dev/null; then
      sudo sed -i '/^deb[[:space:]]/ s/$/ contrib non-free non-free-firmware/' "$sources_list" 2> /dev/null || true
      sudo apt update -qq 2> /dev/null || true
    fi
  fi
}
