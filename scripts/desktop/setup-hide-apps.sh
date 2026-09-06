#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

APPS=(
  assistant
  avahi-discover
  bottom
  bssh
  btop
  bvnc
  designer
  display-im7.q16
  linguist
  lstopo
  mpv
  nm-connection-editor
  nvim
  org.gnome.Extensions
  org.gnome.Tour
  qdbusviewer
  qv4l2
  qvidcap
)

_get_target_dir() {
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
}

_hide_app() {
  local app="$1"
  local default_location="/usr/share/applications/${app}.desktop"

  if [ ! -f "${default_location}" ] && [ -f "/usr/local/share/applications/${app}.desktop" ]; then
    default_location="/usr/local/share/applications/${app}.desktop"
  fi

  if [ -f "${default_location}" ]; then
    local target_dir
    target_dir="$(_get_target_dir)"
    mkdir -p "${target_dir}"

    local home_location="${target_dir}/${app}.desktop"
    cp "${default_location}" "${home_location}"
    sed -i "s/NoDisplay=\(true\|false\)//g" "${home_location}" > /dev/null
    echo "NoDisplay=true" | tee -a "${home_location}" > /dev/null
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

  echo "Desktop applications hidden."
}

main() {
  _hide_desktop_apps
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
