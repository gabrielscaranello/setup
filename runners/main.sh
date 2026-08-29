#!/bin/bash
set -euo pipefail

RUNNERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

# Source utilities for package manager and distro detection
source "$SCRIPTS_DIR/_utils.sh" 2>/dev/null || true

show_help() {
  cat << 'HELP_EOF'
=======================================
   Desktop Setup - CLI & Orchestrator
=======================================

Usage:
  ./main.sh [command]
  make [command]

Available Commands:
  help                  - Show this help message
  all                   - Run complete desktop setup pipeline for current distribution
  browsers              - Install Web Browsers (Chromium, Firefox)
  dbeaver               - Install DBeaver
  default-apps          - Configure default desktop applications (MIME / Kitty terminal)
  discord               - Install Discord
  docker                - Install Docker engine and plugins (buildx, compose)
  firewall              - Configure Firewall (firewalld on Fedora, UFW on Debian/Arch) and GUI
  flatpak               - Configure Flatpak and Flathub repository
  fonts                 - Install JetBrains Mono Nerd Font
  gimp                  - Install GIMP image editor
  gitflow               - Install Gitflow CJS
  go                    - Install Golang programming language
  kernel-debian         - Install latest Linux kernel and headers from Debian backports
  kitty                 - Install Kitty terminal emulator
  lazydocker            - Install Lazydocker
  lazygit               - Install Lazygit
  neovim                - Install Neovim and build runtime dependencies
  nvm                   - Install NVM, Node.js and global packages
  onlyoffice            - Install ONLYOFFICE Desktop Editors (Flatpak)
  rust                  - Install Rust, Cargo and tools (tree-sitter-cli)
  swap                  - Configure Swap and VM memory tuning
  telegram              - Install Telegram Desktop
  timeshift             - Install and configure Timeshift (Btrfs / Rsync)
  vscodium              - Install VSCodium (Code - OSS on Arch)
HELP_EOF
}

run_all() {
  local package_manager
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution: Unable to detect package manager" >&2
    return 1
  }

  case "$package_manager" in
  apt)
    echo "Delegating complete setup to Debian runner..."
    bash "$RUNNERS_DIR/debian.sh"
    ;;

  dnf)
    echo "Delegating complete setup to Fedora runner..."
    bash "$RUNNERS_DIR/fedora.sh"
    ;;

  pacman)
    echo "Delegating complete setup to Arch Linux runner..."
    bash "$RUNNERS_DIR/arch.sh"
    ;;

  *)
    echo "Unsupported package manager for runner dispatch: $package_manager" >&2
    return 1
    ;;
  esac
}

run_module() {
  local target="$1"

  case "$target" in
  help | --help | -h)
    show_help
    ;;

  all)
    run_all
    ;;

  browsers)
    bash "$SCRIPTS_DIR/apps/setup-browsers.sh"
    ;;

  dbeaver)
    bash "$SCRIPTS_DIR/apps/setup-dbeaver.sh"
    ;;

  default-apps)
    bash "$SCRIPTS_DIR/apps/setup-default-apps.sh"
    ;;

  discord)
    bash "$SCRIPTS_DIR/apps/setup-discord.sh"
    ;;

  docker)
    bash "$SCRIPTS_DIR/toolchain/setup-docker.sh"
    ;;

  firewall)
    bash "$SCRIPTS_DIR/security/setup-firewall.sh"
    ;;

  flatpak)
    bash "$SCRIPTS_DIR/system/setup-flatpak.sh"
    ;;

  fonts)
    bash "$SCRIPTS_DIR/terminal/setup-fonts.sh"
    ;;

  gimp)
    bash "$SCRIPTS_DIR/apps/setup-gimp.sh"
    ;;

  gitflow)
    bash "$SCRIPTS_DIR/toolchain/setup-gitflow.sh"
    ;;

  go)
    bash "$SCRIPTS_DIR/toolchain/setup-go.sh"
    ;;

  kernel-debian)
    bash "$SCRIPTS_DIR/system/debian/setup-kernel.sh"
    ;;

  kitty)
    bash "$SCRIPTS_DIR/terminal/setup-kitty.sh"
    ;;

  lazydocker)
    bash "$SCRIPTS_DIR/terminal/setup-lazydocker.sh"
    ;;

  lazygit)
    bash "$SCRIPTS_DIR/terminal/setup-lazygit.sh"
    ;;

  neovim)
    bash "$SCRIPTS_DIR/toolchain/setup-neovim.sh"
    ;;

  nvm)
    bash "$SCRIPTS_DIR/toolchain/setup-nvm.sh"
    ;;

  onlyoffice)
    bash "$SCRIPTS_DIR/apps/setup-onlyoffice.sh"
    ;;

  rust)
    bash "$SCRIPTS_DIR/toolchain/setup-rust.sh"
    ;;

  swap)
    bash "$SCRIPTS_DIR/system/setup-swap.sh"
    ;;

  telegram)
    bash "$SCRIPTS_DIR/apps/setup-telegram.sh"
    ;;

  timeshift)
    bash "$SCRIPTS_DIR/system/setup-timeshift.sh"
    ;;

  vscodium)
    bash "$SCRIPTS_DIR/apps/setup-vscodium.sh"
    ;;

  *)
    echo "Unknown command: $target" >&2
    echo "" >&2
    show_help >&2
    return 1
    ;;
  esac
}

main() {
  if [ $# -eq 0 ]; then
    show_help
  else
    run_module "$1"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
