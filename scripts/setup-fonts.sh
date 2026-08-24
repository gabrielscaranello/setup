#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

FONT_ARCHIVE="JetBrainsMono.zip"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}"
TARGET_DIR="$HOME/.fonts"

_is_font_installed() {
  if [ -d "$TARGET_DIR" ]; then
    if ls "$TARGET_DIR"/JetBrainsMonoNerdFont*.ttf >/dev/null 2>&1; then
      return 0
    fi
  fi
  if command -v fc-list >/dev/null 2>&1; then
    if fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
      return 0
    fi
  fi
  return 1
}

_install_fonts_from_upstream() {
  if _is_font_installed; then
    echo "JetBrains Mono Nerd Font is already installed, skipping."
    return 0
  fi

  local work_dir="/tmp/JetBrainsMono"
  local archive_file="/tmp/${FONT_ARCHIVE}"

  echo "Installing JetBrains Mono Nerd Font from upstream release..."

  echo "Cleaning up temporary directories..."
  rm -rf "$archive_file" "$work_dir"
  mkdir -p "$work_dir" "$TARGET_DIR"

  echo "Downloading JetBrains Mono Nerd Font..."
  download_file "$DOWNLOAD_URL" "$archive_file"

  echo "Extracting font files..."
  unzip -q "$archive_file" -d "$work_dir"

  echo "Copying fonts to $TARGET_DIR..."
  for font in "$work_dir"/JetBrainsMonoNerdFont-Regular.ttf "$work_dir"/JetBrainsMonoNerdFont-Bold.ttf "$work_dir"/JetBrainsMonoNerdFont-Italic.ttf; do
    if [ -f "$font" ]; then
      cp "$font" "$TARGET_DIR/"
    fi
  done

  echo "Cleaning temporary files..."
  rm -rf "$archive_file" "$work_dir"

  echo "Updating font cache..."
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$TARGET_DIR" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1 || true
  fi

  echo "JetBrains Mono Nerd Font installed successfully."
}

_install_fonts_repo() {
  echo "Installing JetBrains Mono Nerd Font from repository..."
  install_packages fonts-jetbrains-mono-nerd
}

_install_distro_fonts() {
  echo "Installing system font packages from repositories..."
  install_packages fonts-liberation fonts-roboto fonts-carlito fonts-noto fonts-noto-color-emoji
}

_install_fonts() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  _install_distro_fonts

  case "$pm" in
  pacman)
    _install_fonts_repo
    ;;
  apt | dnf)
    install_packages curl wget unzip fontconfig || true
    _install_fonts_from_upstream
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up Fonts (JetBrains Mono Nerd Font & System Fonts)..."
  _install_fonts
  echo "setup-fonts complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
