#!/bin/bash

# Desktop dconf helper functions (sourced as utility, not executed directly)

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

ensure_dconf() {
  if ! command -v dconf > /dev/null 2>&1 || (! command -v dbus-run-session > /dev/null 2>&1 && [ ! -x "/usr/sbin/dbus-run-session" ]); then
    echo "dconf not found in PATH, attempting to install..."
    install_packages dconf || true
  fi

  if ! command -v dconf > /dev/null 2>&1; then
    echo "Error: dconf CLI is not installed or not found in PATH." >&2
    return 1
  fi

  if [ ! -s /etc/machine-id ] && [ ! -s /var/lib/dbus/machine-id ]; then
    if command -v dbus-uuidgen > /dev/null 2>&1; then
      if [ -w /etc ]; then
        dbus-uuidgen --ensure 2> /dev/null || true
      elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
        sudo dbus-uuidgen --ensure 2> /dev/null || true
      fi
    elif [ -w /etc ]; then
      od -vN 16 -An -tx1 /dev/urandom 2> /dev/null | tr -d ' \n' > /etc/machine-id 2> /dev/null || true
    elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
      od -vN 16 -An -tx1 /dev/urandom 2> /dev/null | tr -d ' \n' | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    fi
  fi
}

# Runs a command inside a D-Bus session when none is active.
# If <cmd> is a shell function (e.g. a Bats mock) and dbus-run-session is not
# itself mocked, the function is invoked directly.
_dbus_session_exec() {
  local cmd="$1"
  shift

  if [ "$(type -t "$cmd" 2> /dev/null || true)" = "function" ] \
    && [ "$(type -t dbus-run-session 2> /dev/null || true)" != "function" ]; then
    "$cmd" "$@"
    return $?
  fi

  local dbus_cmd="dbus-run-session"
  if ! command -v "$dbus_cmd" > /dev/null 2>&1 && [ -x "/usr/sbin/dbus-run-session" ]; then
    dbus_cmd="/usr/sbin/dbus-run-session"
  fi

  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v "$dbus_cmd" > /dev/null 2>&1; then
    "$dbus_cmd" -- "$cmd" "$@"
  else
    "$cmd" "$@"
  fi
}

dconf_exec() {
  _dbus_session_exec dconf "$@"
}

gsettings_exec() {
  _dbus_session_exec gsettings "$@"
}

load_dconf_file() {
  local file_path="$1"
  local name
  name="$(basename "$file_path")"

  if [ ! -f "$file_path" ]; then
    echo "  Warning: Configuration file '$file_path' not found. Skipping." >&2
    return 0
  fi

  echo "  Loading dconf configuration: $name..."
  dconf_exec load / < "$file_path"
}

load_dconf_files() {
  local base_dir="$1"
  shift
  local files=("$@")

  if [ ! -d "$base_dir" ]; then
    echo "Error: Configuration directory '$base_dir' not found." >&2
    return 1
  fi

  for file in "${files[@]}"; do
    load_dconf_file "${base_dir}/${file}"
  done
}

format_gvariant_array() {
  local formatted=""
  local item
  for item in "$@"; do
    [ -n "$item" ] || continue
    if [ -z "$formatted" ]; then
      formatted="'$item'"
    else
      formatted="$formatted, '$item'"
    fi
  done
  echo "[$formatted]"
}

merge_gvariant_array() {
  local current_raw="$1"
  shift
  local new_items=("$@")

  local -a items=()
  if [ -n "$current_raw" ]; then
    local line
    while IFS= read -r line; do
      [ -n "$line" ] && items+=("$line")
    done < <(echo "$current_raw" | grep -oE "'[^']+'|\"[^\"]+\"" | tr -d "'\"" || true)
  fi

  local arg
  for arg in "${new_items[@]}"; do
    [ -n "$arg" ] || continue
    local found=0
    local it
    for it in "${items[@]}"; do
      if [ "$it" = "$arg" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      items+=("$arg")
    fi
  done

  format_gvariant_array "${items[@]}"
}
