#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || source "scripts/_utils.sh" 2> /dev/null || true

APPS=(
  assistant
  avahi-discover
  bottom
  bssh
  bvnc
  cups
  debian-uxterm
  debian-xterm
  designer
  display-im7.q16
  linguist
  lstopo
  mpv
  nm-connection-editor
  org.gnome.Extensions
  org.gnome.Tour
  org.kde.drkonqi.coredump.gui
  python3
  python3.11
  python3.12
  python3.13
  qdbusviewer
  qv4l2
  qvidcap
  system-config-printer
  uxterm
  xterm
)

UNHIDE_APPS=(
  btop
  nvim
)

_get_target_dir() {
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
}

_hide_app() {
  local app="$1"
  local default_dir="${SYSTEM_APPLICATIONS_DIR:-/usr/share/applications}"
  local local_dir="${LOCAL_APPLICATIONS_DIR:-/usr/local/share/applications}"

  local -a candidates=()
  local dir
  for dir in "$default_dir" "$local_dir"; do
    if [ -f "${dir}/${app}.desktop" ]; then
      candidates+=("${dir}/${app}.desktop")
    elif compgen -G "${dir}/${app}.desktop" > /dev/null 2>&1; then
      local match
      for match in ${dir}/${app}.desktop; do
        [ -f "$match" ] && candidates+=("$match")
      done
    fi
  done

  local target_dir
  target_dir="$(_get_target_dir)"

  local file
  for file in "${candidates[@]}"; do
    local base_name
    base_name="$(basename "$file")"
    mkdir -p "${target_dir}"

    local home_location="${target_dir}/${base_name}"
    rm -f "${home_location}"
    cp "${file}" "${home_location}"
    chmod u+w "${home_location}"
    write_ini_key "${home_location}" "Desktop Entry" "NoDisplay" "true"
  done
}

_unhide_app() {
  local app="$1"
  local target_dir
  target_dir="$(_get_target_dir)"
  local home_location="${target_dir}/${app}.desktop"

  if [ -f "${home_location}" ] && grep -q "^NoDisplay=true" "${home_location}" 2> /dev/null; then
    rm -f "${home_location}"
  fi
}

_hide_desktop_apps() {
  echo "Hiding unwanted desktop applications..."

  local target_dir
  target_dir="$(_get_target_dir)"
  mkdir -p "${target_dir}"

  local app
  for app in "${APPS[@]}"; do
    _hide_app "$app"
  done

  for app in "${UNHIDE_APPS[@]}"; do
    _unhide_app "$app"
  done

  if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database "${target_dir}" > /dev/null 2>&1 || true
  fi

  echo "Desktop applications hidden."
}

main() {
  _hide_desktop_apps
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
