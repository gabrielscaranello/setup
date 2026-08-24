#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

TELEGRAM_API_URL="https://api.github.com/repos/telegramdesktop/tdesktop/releases/latest"

_fetch_remote_version() {
  local version=""
  version="$(fetch_url "$TELEGRAM_API_URL" | grep -Po '"tag_name":\s*"v\K[^"]*' || true)"
  echo "$version" | tr -d '[:space:]'
}

_get_local_version() {
  if [ -x "$HOME/.local/opt/telegram-desktop/Telegram" ]; then
    "$HOME/.local/opt/telegram-desktop/Telegram" --version 2>/dev/null | grep -Po 'Telegram Desktop \K[^ ]*' || true
  elif command -v telegram-desktop >/dev/null 2>&1; then
    telegram-desktop --version 2>/dev/null | grep -Po 'Telegram Desktop \K[^ ]*' || true
  elif [ -x "$HOME/.local/bin/telegram-desktop" ]; then
    "$HOME/.local/bin/telegram-desktop" --version 2>/dev/null | grep -Po 'Telegram Desktop \K[^ ]*' || true
  fi
}

_is_telegram_up_to_date() {
  local local_ver remote_ver
  local_ver="$(_get_local_version)"
  if [ -z "$local_ver" ]; then
    return 1
  fi

  remote_ver="$(_fetch_remote_version)"
  if [ -n "$remote_ver" ] && [ "$local_ver" = "$remote_ver" ]; then
    return 0
  fi

  return 1
}

_setup_desktop_integration() {
  local opt_dir="$HOME/.local/opt/telegram-desktop"
  local bin_dir="$HOME/.local/bin"
  local apps_dir="$HOME/.local/share/applications"

  mkdir -p "$bin_dir" "$apps_dir"

  # Create symlink in ~/.local/bin
  if [ -x "$opt_dir/Telegram" ]; then
    ln -sf "$opt_dir/Telegram" "$bin_dir/telegram-desktop"
  fi

  # Create desktop entry if it doesn't already exist or to point to correct binary
  local desktop_file="$apps_dir/telegramdesktop.desktop"
  cat <<DESKTOP >"$desktop_file"
[Desktop Entry]
Name=Telegram Desktop
Comment=Official desktop version of Telegram messaging app
Exec=$opt_dir/Telegram -- %u
Icon=telegram
Terminal=false
Type=Application
Categories=Network;InstantMessaging;Chat;
MimeType=x-scheme-handler/tg;
Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;
DESKTOP
}

_install_telegram_binary() {
  local latest_version
  latest_version="$(_fetch_remote_version)"

  if [ -z "$latest_version" ]; then
    echo "Warning: Could not fetch latest Telegram version from GitHub API" >&2
  fi

  if [ -n "$latest_version" ] && _is_telegram_up_to_date; then
    echo "Telegram is already up to date (version: ${latest_version}), skipping installation."
    _setup_desktop_integration
    return 0
  fi

  install_packages curl wget tar xz-utils || true

  # Fallback if latest_version was empty
  if [ -z "$latest_version" ]; then
    latest_version="$(_fetch_remote_version)"
    if [ -z "$latest_version" ]; then
      echo "Failed to determine latest Telegram release version" >&2
      return 1
    fi
  fi

  local file_name="tsetup.${latest_version}.tar.xz"
  local download_url="https://github.com/telegramdesktop/tdesktop/releases/download/v${latest_version}/${file_name}"
  local output_dir="/tmp/${file_name}"
  local extract_dir="/tmp/Telegram"
  local opt_dir="$HOME/.local/opt"
  local target_dir="$opt_dir/telegram-desktop"

  echo "Installing Telegram ($latest_version)..."

  echo "Removing old files if they exist..."
  rm -rf "$output_dir" "$target_dir" "$extract_dir"

  echo "Downloading Telegram..."
  download_file "$download_url" "$output_dir"

  echo "Extracting Telegram..."
  mkdir -p "$opt_dir"
  tar -xf "$output_dir" -C /tmp
  mv "$extract_dir" "$target_dir"

  rm -f "$output_dir"

  _setup_desktop_integration

  echo "Telegram installed into $target_dir."
}

_add_rpmfusion_free_repo() {
  if dnf repolist 2>/dev/null | grep -qi "rpmfusion-free"; then
    echo "RPM Fusion Free repository is already configured, skipping."
    return 0
  fi

  echo "Adding RPM Fusion Free repository..."
  local fedora_version
  fedora_version="$(rpm -E %fedora 2>/dev/null || echo "")"
  if [ -z "$fedora_version" ] || [ "$fedora_version" = "%fedora" ]; then
    fedora_version="41"
  fi

  sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" || true
}

_install_telegram_repo() {
  local pm="$1"
  if [ "$pm" = "dnf" ]; then
    _add_rpmfusion_free_repo
  fi

  echo "Installing telegram-desktop package..."
  install_packages telegram-desktop
}

_install_telegram() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    _install_telegram_repo "$pm"
    ;;
  apt)
    _install_telegram_binary
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up Telegram Desktop..."
  _install_telegram
  echo "setup-telegram complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
