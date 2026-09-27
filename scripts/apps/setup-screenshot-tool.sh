#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/desktop/_dconf.sh" 2> /dev/null || true

_configure_cinnamon_shortcuts() {
  if command -v ensure_dconf > /dev/null 2>&1; then
    ensure_dconf || return 0
  elif ! command -v dconf > /dev/null 2>&1; then
    echo "dconf not found. Skipping Cinnamon shortcut configuration."
    return 0
  fi

  command -v dconf > /dev/null 2>&1 || return 0

  echo "Configuring Flameshot shortcuts for Cinnamon..."

  local current_list
  current_list="$(dconf_exec read /org/cinnamon/desktop/keybindings/custom-list 2> /dev/null || true)"

  local target_slot=""
  local -a existing_slots=()

  if [[ -n "$current_list" && "$current_list" =~ custom[0-9]+ ]]; then
    while read -r slot; do
      [ -n "$slot" ] || continue
      existing_slots+=("$slot")
      local cmd
      cmd="$(dconf_exec read "/org/cinnamon/desktop/keybindings/custom-keybindings/${slot}/command" 2> /dev/null || true)"
      if [[ "$cmd" == *"flameshot"* ]]; then
        target_slot="$slot"
        break
      fi
    done < <(grep -oE 'custom[0-9]+' <<< "$current_list")
  fi

  if [ -z "$target_slot" ]; then
    local idx=0
    while :; do
      local candidate="custom${idx}"
      local found=0
      for s in "${existing_slots[@]:-}"; do
        if [ "$s" = "$candidate" ]; then
          found=1
          break
        fi
      done
      if [ "$found" -eq 0 ]; then
        target_slot="$candidate"
        break
      fi
      idx=$((idx + 1))
    done

    local new_list
    if [[ -z "$current_list" || "$current_list" == "[]" || "$current_list" == "@as []" ]]; then
      new_list="['${target_slot}']"
    else
      new_list="${current_list%]*}, '${target_slot}']"
    fi
    dconf_exec write /org/cinnamon/desktop/keybindings/custom-list "$new_list" 2> /dev/null || true
  fi

  dconf_exec write "/org/cinnamon/desktop/keybindings/custom-keybindings/${target_slot}/name" "'Flameshot'" 2> /dev/null || true
  dconf_exec write "/org/cinnamon/desktop/keybindings/custom-keybindings/${target_slot}/command" "'flameshot gui'" 2> /dev/null || true
  dconf_exec write "/org/cinnamon/desktop/keybindings/custom-keybindings/${target_slot}/binding" "['Print', '<Primary><Alt>s']" 2> /dev/null || true

  # Disable default Cinnamon screenshot binding to prevent conflict with Print key
  dconf_exec write /org/cinnamon/desktop/keybindings/media-keys/screenshot "@as []" 2> /dev/null || true
}

_install_screenshot_tool() {
  require_supported_distro > /dev/null || return 1

  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Installing Flameshot for GNOME..."
      install_packages flameshot
      ;;
    plasma)
      echo "Installing Spectacle for KDE Plasma..."
      install_packages spectacle
      ;;
    cinnamon)
      echo "Installing Flameshot for Cinnamon..."
      install_packages flameshot
      _configure_cinnamon_shortcuts
      ;;
    *)
      echo "Unrecognized desktop environment: $de. Skipping screenshot tool setup."
      return 0
      ;;
  esac
}

main() {
  echo "Setting up screenshot tool..."
  _install_screenshot_tool
  echo "setup-screenshot complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
