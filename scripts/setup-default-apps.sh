#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_set_default_terminal_xdg() {
  local desktop_file="kitty.desktop"

  mkdir -p "$HOME/.config"

  # Standard XDG terminal list specification
  echo "$desktop_file" >"$HOME/.config/xdg-terminals.list"

  # MIME handler for terminal schemes if xdg-mime is available
  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "$desktop_file" x-scheme-handler/terminal 2>/dev/null || true
  fi
}

_set_default_terminal_gnome() {
  if ! command -v gsettings >/dev/null 2>&1; then
    return 0
  fi

  # Legacy GNOME schema compatibility
  if gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.desktop.default-applications.terminal"; then
    gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2>/dev/null || true
  fi
}

_set_default_terminal_plasma() {
  # KDE Plasma terminal configuration in ~/.config/kdeglobals
  local kdeglobals="$HOME/.config/kdeglobals"

  mkdir -p "$HOME/.config"

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true
  elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
    kwriteconfig5 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true
  else
    # Fallback to direct file modification if kwriteconfig is not present
    if [ -f "$kdeglobals" ]; then
      if grep -q "^\[General\]" "$kdeglobals"; then
        if grep -q "^TerminalApplication=" "$kdeglobals"; then
          sed -i "s|^TerminalApplication=.*|TerminalApplication=kitty|" "$kdeglobals"
        else
          sed -i "/^\[General\]/a TerminalApplication=kitty" "$kdeglobals"
        fi
        if grep -q "^TerminalService=" "$kdeglobals"; then
          sed -i "s|^TerminalService=.*|TerminalService=kitty.desktop|" "$kdeglobals"
        else
          sed -i "/^\[General\]/a TerminalService=kitty.desktop" "$kdeglobals"
        fi
      else
        cat <<INNER_EOF >>"$kdeglobals"

[General]
TerminalApplication=kitty
TerminalService=kitty.desktop
INNER_EOF
      fi
    else
      cat <<INNER_EOF >"$kdeglobals"
[General]
TerminalApplication=kitty
TerminalService=kitty.desktop
INNER_EOF
    fi
  fi
}

_set_default_terminal() {
  local de
  de="$(get_desktop_environment)"

  echo "Setting Kitty as the default terminal emulator (Desktop environment: $de)..."
  _set_default_terminal_xdg

  case "$de" in
  gnome)
    _set_default_terminal_gnome
    ;;
  plasma)
    _set_default_terminal_plasma
    ;;
  *)
    # For unrecognized desktop environments, do not apply DE-specific configurations
    ;;
  esac

  echo "Default terminal emulator configured successfully."
}

_set_default_apps() {
  _set_default_terminal
}

main() {
  echo "Configuring default desktop applications..."
  _set_default_apps
  echo "setup-default-apps complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
