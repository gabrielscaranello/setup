#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

GO_VERSION="1.24.0"
GO_PACKAGES=("github.com/reteps/dockerfmt@latest")

_install_prereqs() {
  install_packages curl wget tar git || true
}

_setup_shell_profile() {
  local profile
  profile="$(get_shell_profile)"

  if grep -q '/usr/local/go/bin' "$profile" 2>/dev/null; then
    echo "Go PATH already configured in $profile, skipping"
    return 0
  fi

  echo "Adding Go PATH to $profile..."
  cat >> "$profile" << 'EOF_PROFILE'

# Go PATH
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
EOF_PROFILE
}

_is_go_installed_from_binary() {
  if [ -x "/usr/local/go/bin/go" ]; then
    local current_version
    current_version="$(/usr/local/go/bin/go version 2>/dev/null || true)"
    if [[ "$current_version" =~ go$GO_VERSION ]]; then
      return 0
    fi
  fi
  return 1
}

_install_go_from_binary() {
  if _is_go_installed_from_binary; then
    echo "Golang ($GO_VERSION) is already installed in /usr/local/go, skipping."
    return 0
  fi

  local filename="go${GO_VERSION}.linux-amd64.tar.gz"
  local download_url="https://go.dev/dl/${filename}"
  local download_file="/tmp/${filename}"
  local target_dir="/usr/local"
  local install_dir="${target_dir}/go"

  echo "Installing Golang ($GO_VERSION) from upstream binary archive..."

  echo "Removing previous installation..."
  sudo rm -rf "$download_file" "$install_dir"

  echo "Downloading Golang binary..."
  download_file "$download_url" "$download_file"

  echo "Extracting Golang archive..."
  sudo tar -C "$target_dir" -xzf "$download_file"

  echo "Cleaning up download archive..."
  sudo rm -rf "$download_file"

  _setup_shell_profile
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

  echo "Golang installed successfully at $(command -v go || echo '/usr/local/go/bin/go')"
}

_install_go_repo() {
  echo "Installing Golang from distribution repository..."
  install_packages golang
}

_install_go_packages() {
  if [ ${#GO_PACKAGES[@]} -eq 0 ]; then
    return 0
  fi

  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

  echo "Installing Go packages: ${GO_PACKAGES[*]}"
  for pkg in "${GO_PACKAGES[@]}"; do
    local bin_name="${pkg##*/}"
    bin_name="${bin_name%@*}"
    if command -v "$bin_name" >/dev/null 2>&1; then
      echo "$bin_name already installed, skipping"
    else
      echo "Installing $pkg via go install..."
      go install "$pkg"
    fi
  done
}

_install_go() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    _install_go_repo
    ;;
  apt)
    _install_prereqs
    _install_go_from_binary
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac

  _install_go_packages
}

main() {
  echo "Setting up Golang..."
  _install_go
  echo "setup-go complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
