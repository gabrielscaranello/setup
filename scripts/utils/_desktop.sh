#!/bin/bash

# Desktop Environment Detection and Persistence Utilities
# Detects active desktop environment (GNOME / KDE Plasma), prompts for interactive
# selection when headless/unrecognized, and saves state under ~/.config/setup.

get_desktop_environment() {
  local de="${TARGET_DE:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}"
  if [ -z "$de" ] && [ -f "$HOME/.config/setup/desktop-environment" ]; then
    de="$(cat "$HOME/.config/setup/desktop-environment" 2> /dev/null || true)"
  fi
  de="$(echo "$de" | tr '[:upper:]' '[:lower:]')"

  case "$de" in
    *gnome*) echo "gnome" ;;
    *kde* | *plasma*) echo "plasma" ;;
    *cinnamon*) echo "cinnamon" ;;
    *) echo "unknown" ;;
  esac
}

save_desktop_environment() {
  local de="$1"
  export TARGET_DE="$de"
  mkdir -p "$HOME/.config/setup" 2> /dev/null || true
  echo "$de" > "$HOME/.config/setup/desktop-environment" 2> /dev/null || true
}

prompt_desktop_environment() {
  local prompt_label="${1:-Selecione o Desktop Environment:}"
  local default_de="${2:-}"
  if [ -z "$default_de" ]; then
    if [ "$(get_distro_id 2> /dev/null || true)" = "lmde" ]; then
      default_de="cinnamon"
    else
      default_de="plasma"
    fi
  fi

  if [ -t 0 ]; then
    echo "" >&2
    echo "Nenhum ambiente gráfico ativo detectado." >&2
    echo "$prompt_label" >&2
    echo "  1) KDE Plasma" >&2
    echo "  2) GNOME" >&2
    echo "  3) Cinnamon (Padrão no LMDE)" >&2
    echo "" >&2
    local choice=""
    read -r -p "Opção [1-3, padrão: 1]: " choice || true
    case "$choice" in
      2 | [gG]*) echo "gnome" ;;
      3 | [cC]*) echo "cinnamon" ;;
      *) echo "plasma" ;;
    esac
  else
    echo "$default_de"
  fi
}

ensure_desktop_environment() {
  local prompt_label="${1:-Selecione o Desktop Environment:}"
  local de
  de="$(get_desktop_environment)"

  if [ "$de" = "unknown" ]; then
    de="$(prompt_desktop_environment "$prompt_label")"
  fi

  save_desktop_environment "$de"
  echo "$de"
}

resolve_desktop_app() {
  local candidate
  for candidate in "$@"; do
    if [ -f "/usr/share/applications/$candidate" ] \
      || [ -f "/usr/local/share/applications/$candidate" ] \
      || [ -f "/var/lib/flatpak/exports/share/applications/$candidate" ] \
      || [ -f "$HOME/.local/share/flatpak/exports/share/applications/$candidate" ] \
      || [ -f "$HOME/.local/share/applications/$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  echo "$1"
}
