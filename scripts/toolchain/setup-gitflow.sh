#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

GITFLOW_VERSION="v2.2.1"
INSTALLER_URL="https://raw.githubusercontent.com/CJ-Systems/gitflow-cjs/refs/heads/legacy-develop/contrib/gitflow-installer.sh"

_is_gitflow_installed() {
  if command -v git-flow > /dev/null 2>&1; then
    local current_version
    current_version="$(git flow version 2> /dev/null || true)"
    if [[ "$current_version" =~ $GITFLOW_VERSION ]]; then
      return 0
    fi
  fi
  return 1
}

_download_gitflow_installer() {
  local installer_url="$1"
  local installer_file="$2"

  echo "Downloading Gitflow installer..."
  download_file "$installer_url" "$installer_file"
  chmod +x "$installer_file"
}

_run_gitflow_installer() {
  local work_dir="$1"
  local installer_file="$2"
  local version="$3"

  echo "Running installer..."
  (
    cd "$work_dir"
    sudo bash "$installer_file" install version "$version"
  )
}

_install_gitflow() {
  if _is_gitflow_installed; then
    echo "Gitflow CJS ($GITFLOW_VERSION) is already installed, skipping."
    return 0
  fi

  local work_dir="/tmp/gitflow-installer"
  local installer_file="$work_dir/gitflow-installer.sh"

  echo "Installing Gitflow CJS ($GITFLOW_VERSION)..."

  echo "Cleaning temporary build directory..."
  sudo rm -rf "$work_dir"
  mkdir -p "$work_dir"

  _download_gitflow_installer "$INSTALLER_URL" "$installer_file"
  _run_gitflow_installer "$work_dir" "$installer_file" "$GITFLOW_VERSION"

  echo "Cleaning up installer temporary files..."
  sudo rm -rf "$work_dir"

  echo "Gitflow CJS installed successfully at $(command -v git-flow || echo '/usr/local/bin/git-flow')"
}

main() {
  echo "Setting up Gitflow CJS..."
  install_packages curl wget git || true
  _install_gitflow
  echo "setup-gitflow complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
