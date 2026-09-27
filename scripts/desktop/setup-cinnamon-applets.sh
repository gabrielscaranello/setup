#!/bin/bash
set -euo pipefail

# Cinnamon Applets and Extensions (Spices) Setup Script
# Downloads and installs curated applets and extensions from Linux Mint Spices repository.

source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

SPICES_BASE_URL="https://cinnamon-spices.linuxmint.com/files"

APPLETS=(
  "color-picker@fmete"
)

EXTENSIONS=(
  "transparent-panels-reloaded@marcelovbcfilho"
)

_get_cinnamon_dir() {
  echo "$HOME/.local/share/cinnamon"
}

_is_spice_installed() {
  local spice_type="$1"
  local uuid="$2"
  local base_dir
  base_dir="$(_get_cinnamon_dir)"
  [ -d "$base_dir/$spice_type/$uuid" ]
}

_install_spice() {
  local spice_type="$1"
  local uuid="$2"
  local base_dir
  base_dir="$(_get_cinnamon_dir)"
  local target_dir="$base_dir/$spice_type"

  if _is_spice_installed "$spice_type" "$uuid"; then
    echo "  Spice '$uuid' ($spice_type) is already installed."
    return 0
  fi

  echo "  Installing '$uuid' ($spice_type)..."
  mkdir -p "$target_dir"

  local download_url="${SPICES_BASE_URL}/${spice_type}/${uuid}.zip"
  local tmp_zip="/tmp/${uuid}_$$.zip"
  rm -f "$tmp_zip"

  if download_file "$download_url" "$tmp_zip"; then
    unzip -q -o "$tmp_zip" -d "$target_dir"
    rm -f "$tmp_zip"
    echo "  Successfully installed '$uuid'."
  else
    echo "  Failed to download spice package for '$uuid'." >&2
    rm -f "$tmp_zip"
    return 1
  fi
}

_merge_cinnamon_extensions() {
  local current_raw="$1"
  shift
  local new_uuids=("$@")

  local -a items=()
  if [ -n "$current_raw" ]; then
    local line
    while IFS= read -r line; do
      [ -n "$line" ] && items+=("$line")
    done < <(echo "$current_raw" | grep -oE "'[^']+'|\"[^\"]+\"" | tr -d "'\"" || true)
  fi

  for arg in "${new_uuids[@]}"; do
    [ -n "$arg" ] || continue
    local found=0
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

  local formatted=""
  for it in "${items[@]}"; do
    if [ -z "$formatted" ]; then
      formatted="'$it'"
    else
      formatted="$formatted, '$it'"
    fi
  done
  echo "[$formatted]"
}

_enable_cinnamon_extensions() {
  local new_uuids=("$@")
  [ "${#new_uuids[@]}" -gt 0 ] || return 0

  local current=""
  if command -v dconf > /dev/null 2>&1; then
    current="$(dconf read /org/cinnamon/enabled-extensions 2> /dev/null || true)"
  fi
  if [ -z "$current" ] && command -v gsettings > /dev/null 2>&1; then
    current="$(gsettings get org.cinnamon enabled-extensions 2> /dev/null || true)"
  fi

  local merged
  merged="$(_merge_cinnamon_extensions "$current" "${new_uuids[@]}")"

  echo "Persisting enabled Cinnamon extensions..."
  if command -v dconf > /dev/null 2>&1; then
    dconf write /org/cinnamon/enabled-extensions "$merged" 2> /dev/null || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.cinnamon enabled-extensions "$merged" 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (not Cinnamon). Skipping Cinnamon Spices setup."
    return 0
  fi

  echo "Setting up Cinnamon Spices (applets and extensions)..."
  install_packages unzip || true

  echo "Installing Cinnamon applets..."
  for applet in "${APPLETS[@]}"; do
    _install_spice "applets" "$applet"
  done

  echo "Installing Cinnamon extensions..."
  for extension in "${EXTENSIONS[@]}"; do
    _install_spice "extensions" "$extension"
  done

  _enable_cinnamon_extensions "${EXTENSIONS[@]}"

  echo "Cinnamon Spices setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
