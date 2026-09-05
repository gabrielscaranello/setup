#!/bin/bash
set -euo pipefail

RUNNERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

# Source utilities for package manager and distro detection
source "$SCRIPTS_DIR/_utils.sh" 2> /dev/null || true

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
  amd                   - Install AMD GPU drivers, firmware and codecs
  browsers              - Install Web Browsers (Chromium, Firefox)
  codecs                - Install Multimedia Codecs and A/V Plugins
  cursor                - Install and configure Bibata cursor theme (GNOME, KDE Plasma)
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
  mongodb-compass       - Install MongoDB Compass (Flatpak)
  neovim                - Install Neovim and build runtime dependencies
  nvidia                - Install NVIDIA drivers and hybrid GPU tools (switcheroo-control & prime-run)
  nvm                   - Install NVM, Node.js and global packages
  obsidian              - Install Obsidian Knowledge Base
  onlyoffice            - Install ONLYOFFICE Desktop Editors (Flatpak)
  rust                  - Install Rust, Cargo and tools (tree-sitter-cli)
  screenshot            - Configure Screenshot Tool (Flameshot on GNOME, Spectacle on Plasma)
  steam                 - Install Steam and gaming tools (Proton manager, MangoHud, Gamescope)
  swap                  - Configure Swap and VM memory tuning
  telegram              - Install Telegram Desktop
  timeshift             - Install and configure Timeshift (Btrfs / Rsync)
  virtualbox            - Install Oracle VirtualBox and host modules
  vscodium              - Install VSCodium (Code - OSS on Arch)
HELP_EOF
}

run_all() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"

  case "$distro" in
    debian)
      echo "Delegating complete setup to Debian runner..."
      bash "$RUNNERS_DIR/debian.sh"
      ;;

    fedora)
      echo "Delegating complete setup to Fedora runner..."
      bash "$RUNNERS_DIR/fedora.sh"
      ;;

    arch)
      echo "Delegating complete setup to Arch Linux runner..."
      bash "$RUNNERS_DIR/arch.sh"
      ;;

    *)
      if [ -n "$distro" ] && [ "$distro" != "unknown" ]; then
        echo "Unsupported distribution: '$distro'. Only 'debian', 'fedora', and 'arch' are currently supported." >&2
      else
        echo "Unsupported distribution: Unable to detect a supported distribution (debian, fedora, arch)." >&2
      fi
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

    amd)
      bash "$SCRIPTS_DIR/system/setup-amd.sh"
      ;;

    browsers)
      bash "$SCRIPTS_DIR/apps/setup-browsers.sh"
      ;;

    codecs)
      bash "$SCRIPTS_DIR/system/setup-codecs.sh"
      ;;

    cursor)
      bash "$SCRIPTS_DIR/desktop/setup-cursor-theme.sh"
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

    mongodb-compass)
      bash "$SCRIPTS_DIR/apps/setup-mongodb-compass.sh"
      ;;

    neovim)
      bash "$SCRIPTS_DIR/toolchain/setup-neovim.sh"
      ;;

    nvidia)
      bash "$SCRIPTS_DIR/system/setup-nvidia.sh"
      ;;

    nvm)
      bash "$SCRIPTS_DIR/toolchain/setup-nvm.sh"
      ;;

    obsidian)
      bash "$SCRIPTS_DIR/apps/setup-obsidian.sh"
      ;;

    onlyoffice)
      bash "$SCRIPTS_DIR/apps/setup-onlyoffice.sh"
      ;;

    rust)
      bash "$SCRIPTS_DIR/toolchain/setup-rust.sh"
      ;;

    screenshot)
      bash "$SCRIPTS_DIR/apps/setup-screenshot-tool.sh"
      ;;

    steam)
      bash "$SCRIPTS_DIR/apps/setup-steam.sh"
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

    virtualbox)
      bash "$SCRIPTS_DIR/apps/setup-virtualbox.sh"
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
