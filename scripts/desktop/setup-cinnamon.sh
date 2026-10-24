#!/bin/bash
set -euo pipefail

# Source common utilities and dconf helpers
source "scripts/_utils.sh" 2> /dev/null || true
# shellcheck source=scripts/desktop/_dconf.sh
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || source "scripts/desktop/_dconf.sh" 2> /dev/null || true

_configure_cinnamon_interface() {
  echo "Configuring Cinnamon interface and dark mode preferences..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon.desktop.interface color-scheme 'prefer-dark' 2> /dev/null || true
    gsettings_exec set org.x.apps.portal color-scheme 'prefer-dark' 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.interface clock-show-date true 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.interface clock-show-seconds false 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.interface gtk-enable-primary-paste false 2> /dev/null || true
  fi
}

_configure_cinnamon_terminal() {
  echo "Configuring Cinnamon default terminal emulator..."
  if command -v gsettings > /dev/null 2>&1; then
    local terminal_cmd="x-terminal-emulator"
    if command -v kitty > /dev/null 2>&1; then
      terminal_cmd="kitty"
    fi
    gsettings_exec set org.cinnamon.desktop.default-applications.terminal exec "$terminal_cmd" 2> /dev/null || true
  fi
}

_configure_cinnamon_keybindings() {
  echo "Configuring Cinnamon keyboard shortcuts..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0']" 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name "flameshot" 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "flameshot gui" 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Primary><Super>s', '<Shift><Super>s', 'Print']" 2> /dev/null || true
  fi
}

_configure_nemo() {
  echo "Configuring Nemo file manager preferences..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.nemo.desktop volumes-visible false 2> /dev/null || true
    gsettings_exec set org.nemo.desktop show-orphaned-desktop-icons false 2> /dev/null || true
    gsettings_exec set org.nemo.preferences default-folder-viewer 'list-view' 2> /dev/null || true
    gsettings_exec set org.nemo.preferences date-format 'iso' 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (not Cinnamon). Skipping Cinnamon setup."
    return 0
  fi

  echo "Starting Cinnamon desktop preferences configuration..."
  ensure_dconf || return 1

  _configure_cinnamon_interface
  _configure_cinnamon_terminal
  _configure_cinnamon_keybindings
  _configure_nemo

  echo "setup-cinnamon complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
