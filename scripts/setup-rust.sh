#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

RUSTUP_URL="https://sh.rustup.rs"
CARGO_PACKAGES=("tree-sitter-cli")

_install_prereqs() {
  install_packages curl build-tools libclang || true
}

_install_rustup() {
  if command -v rustup >/dev/null 2>&1; then
    echo "Rustup is already installed."
    return 0
  fi

  echo "Installing rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf "$RUSTUP_URL" | sh -s -- -y --default-toolchain stable --no-modify-path
}

_setup_shell_profile() {
  local profile
  profile="$(get_shell_profile)"

  if grep -q 'cargo/env' "$profile" 2>/dev/null; then
    echo "Rust/cargo already configured in $profile, skipping"
    return 0
  fi

  echo "Adding cargo env to $profile..."
  cat >> "$profile" << 'EOF_PROFILE'

# Rust / Cargo
[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"
EOF_PROFILE
}

_source_cargo() {
  if [ -s "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
    return 0
  fi

  if command -v cargo >/dev/null 2>&1; then
    return 0
  fi

  echo "Cargo environment not found" >&2
  return 1
}

_install_cargo_packages() {
  if [ ${#CARGO_PACKAGES[@]} -eq 0 ]; then
    echo "No cargo packages to install"
    return 0
  fi

  echo "Installing cargo packages: ${CARGO_PACKAGES[*]}"
  for pkg in "${CARGO_PACKAGES[@]}"; do
    if cargo install --list 2>/dev/null | grep -q "^${pkg} "; then
      echo "$pkg already installed, skipping"
    else
      echo "Installing $pkg via cargo..."
      cargo install "$pkg"
    fi
  done
}

main() {
  echo "Setting up Rust / Cargo..."

  _install_prereqs
  _install_rustup
  _setup_shell_profile
  _source_cargo
  rustup default stable 2>/dev/null || true
  _install_cargo_packages

  echo "setup-rust complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
