#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

GITFLOW_VERSION="v2.2.1"
INSTALLER_URL="https://raw.githubusercontent.com/CJ-Systems/gitflow-cjs/refs/heads/legacy-develop/contrib/gitflow-installer.sh"

_install_prereqs() {
  install_packages curl wget git || true
}

_is_gitflow_installed() {
  if command -v git-flow >/dev/null 2>&1; then
    local current_version
    current_version="$(git flow version 2>/dev/null || true)"
    if [[ "$current_version" =~ $GITFLOW_VERSION ]]; then
      return 0
    fi
  fi
  return 1
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

  echo "Downloading Gitflow installer..."
  download_file "$INSTALLER_URL" "$installer_file"

  chmod +x "$installer_file"

  echo "Running installer..."
  (
    cd "$work_dir"
    sudo bash "$installer_file" install version "$GITFLOW_VERSION"
  )

  echo "Cleaning up installer temporary files..."
  sudo rm -rf "$work_dir"

  echo "Gitflow CJS installed successfully at $(command -v git-flow || echo '/usr/local/bin/git-flow')"
}

main() {
  echo "Setting up Gitflow CJS..."
  _install_prereqs
  _install_gitflow
  echo "setup-gitflow complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
