#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config/gnome"

GNOME_DCONF_FILES=(
  "interface.dconf"
  "peripherals.dconf"
  "window-manager.dconf"
  "night-light.dconf"
  "privacy.dconf"
  "nautilus.dconf"
  "shell.dconf"
  "apps.dconf"
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

_configure_gnome_preferences() {
  if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Configuration directory '$CONFIG_DIR' not found." >&2
    return 1
  fi

  echo "Applying GNOME desktop environment preferences..."
  for conf in "${GNOME_DCONF_FILES[@]}"; do
    _load_dconf_file "${CONFIG_DIR}/${conf}"
  done
}

main() {
  set -euo pipefail
  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Starting GNOME desktop preferences configuration..."
      _ensure_dconf || return 1
      _configure_gnome_preferences || return 1
      echo "GNOME desktop preferences configuration completed successfully."
      ;;
    plasma)
      echo "KDE Plasma desktop environment preferences are not yet implemented. Skipping."
      return 0
      ;;
    *)
      echo "Desktop Environment is '$de' (unsupported or not GNOME). Skipping desktop preferences configuration."
      return 0
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
