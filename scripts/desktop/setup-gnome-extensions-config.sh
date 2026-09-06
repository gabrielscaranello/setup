#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true

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
  dconf_exec write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image "$icon_id"
}

_configure_arch_update() {
  if is_distro "arch"; then
    echo "Configuring Arch Linux Updates Indicator extension..."
    load_dconf_file "${CONFIG_DIR}/arch-update.dconf"
  fi
}

main() {
  set -euo pipefail
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ]; then
    echo "Desktop Environment is '$de' (not GNOME). Skipping GNOME extensions configuration."
    return 0
  fi

  echo "Starting GNOME extensions configuration..."

  ensure_dconf || return 1
  echo "Applying common GNOME extensions configuration..."
  load_dconf_files "$CONFIG_DIR" "${COMMON_DCONF_FILES[@]}" || return 1
  _configure_logo_menu_icon
  _configure_arch_update

  echo "GNOME extensions configuration completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
