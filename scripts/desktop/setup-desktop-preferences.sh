#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true

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

main() {
  set -euo pipefail
  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Starting GNOME desktop preferences configuration..."
      ensure_dconf || return 1
      echo "Applying GNOME desktop environment preferences..."
      load_dconf_files "$CONFIG_DIR" "${GNOME_DCONF_FILES[@]}" || return 1
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
