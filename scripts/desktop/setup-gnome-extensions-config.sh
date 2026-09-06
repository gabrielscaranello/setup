#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config/gnome-extensions"

COMMON_DCONF_FILES=(
  "alphabetical-app-grid.dconf"
  "blur-my-shell.dconf"
  "caffeine.dconf"
  "coverflow-alt-tab.dconf"
  "logo-menu.dconf"
  "status-tray.dconf"
  "top-bar-organizer.dconf"
  "vitals.dconf"
)

_ensure_dconf() {
  if ! command -v dconf > /dev/null 2>&1; then
    echo "dconf not found in PATH, attempting to install..."
    install_packages dconf || true
  fi

  if ! command -v dconf > /dev/null 2>&1; then
    echo "Error: dconf CLI is not installed or not found in PATH." >&2
    return 1
  fi
}

_dconf() {
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session > /dev/null 2>&1; then
    dbus-run-session -- dconf "$@"
  else
    dconf "$@"
  fi
}

_load_dconf_file() {
  local file_path="$1"
  local name
  name="$(basename "$file_path")"

  if [ ! -f "$file_path" ]; then
    echo "  Warning: Configuration file '$file_path' not found. Skipping." >&2
    return 0
  fi

  echo "  Loading dconf configuration: $name..."
  _dconf load / < "$file_path"
}

_configure_common_extensions() {
  echo "Applying common GNOME extensions configuration..."
  for conf in "${COMMON_DCONF_FILES[@]}"; do
    _load_dconf_file "${CONFIG_DIR}/${conf}"
  done
}

_configure_logo_menu_icon() {
  local distro icon_id
  distro="$(get_distro_id)"

  case "$distro" in
    fedora)
      icon_id=1
      ;;
    debian)
      icon_id=2
      ;;
    arch)
      icon_id=6
      ;;
    *)
      echo "  Unknown distribution '$distro' for Logo Menu icon. Keeping default."
      return 0
      ;;
  esac

  echo "  Setting Logo Menu icon for $distro (index: $icon_id)..."
  _dconf write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image "$icon_id"
}

_configure_arch_update() {
  if is_distro "arch"; then
    echo "Configuring Arch Linux Updates Indicator extension..."
    _load_dconf_file "${CONFIG_DIR}/arch-update.dconf"
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ]; then
    echo "Desktop Environment is '$de' (not GNOME). Skipping GNOME extensions configuration."
    return 0
  fi

  echo "Starting GNOME extensions configuration..."

  _ensure_dconf
  _configure_common_extensions
  _configure_logo_menu_icon
  _configure_arch_update

  echo "GNOME extensions configuration completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
