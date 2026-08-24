#!/bin/bash

# Debian-specific repository helper functions (sourced as utility, not executed directly)

_get_debian_codename() {
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

  # Fallback to bookworm if detection fails
  echo "bookworm"
}

_is_debian_backports_configured() {
  local codename="${1:-$(_get_debian_codename)}"
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
  codename="$(_get_debian_codename)"
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
  sudo apt-get update -qq
}
