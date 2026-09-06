#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

COMMON_EXTENSIONS=(
  "4269:AlphabeticalAppGrid@stuarthayhurst:Alphabetical App Grid"
  "3193:blur-my-shell@aunetx:Blur my Shell"
  "517:caffeine@patapon.info:Caffeine"
  "3396:color-picker@tuberry:Color Picker"
  "97:CoverflowAltTab@palatis.blogspot.com:Coverflow Alt-Tab"
  "6242:emoji-copy@felipeftn:Emoji Copy"
  "744:Hide_Activities@shay.shayel.org:Hide Activities Button"
  "4451:logomenu@aryan_k:Logo Menu"
  "9164:status-tray@keithvassallo.com:Status Tray"
  "4356:top-bar-organizer@julian.gse.jsts.xyz:Top Bar Organizer"
  "1460:Vitals@CoreCoding.com:Vitals"
)

ARCH_EXTENSIONS=(
  "1010:arch-update@RaphaelRochet:Arch Linux Updates Indicator"
)

_get_gnome_shell_major_version() {
  if ! command -v gnome-shell > /dev/null 2>&1; then
    echo "Error: gnome-shell is not installed or not found in PATH." >&2
    return 1
  fi
  local ver
  ver="$(gnome-shell --version 2> /dev/null | grep -oE '[0-9]+(\.[0-9]+)*' | cut -d. -f1 || true)"
  if [ -n "$ver" ]; then
    echo "$ver"
    return 0
  fi
  echo "Error: Unable to determine GNOME Shell major version." >&2
  return 1
}

_get_installed_extension_version() {
  local uuid="$1"
  local metadata_file="$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json"

  if [ -f "$metadata_file" ]; then
    grep -oE '"version": *[0-9]+' "$metadata_file" | cut -d: -f2 | tr -d ' ' || true
  fi
}

_fetch_extension_api_data() {
  local ext_id="$1"
  local shell_ver="$2"
  fetch_url "https://extensions.gnome.org/extension-info/?pk=${ext_id}&shell_version=${shell_ver}"
}

_parse_api_field() {
  local json_str="$1"
  local field="$2"

  if command -v python3 > /dev/null 2>&1; then
    python3 -c "import sys, json; data=json.loads(sys.argv[1]); val=data.get(sys.argv[2], ''); print(val if val is not None else '')" "$json_str" "$field" 2> /dev/null || true
  else
    grep -oE "\"$field\": *(\"[^\"]+\"|[0-9]+)" <<< "$json_str" | tail -n1 | sed -E "s/\"$field\": *//; s/\"//g" || true
  fi
}

_resolve_extension_url() {
  local download_url="$1"

  if [[ "$download_url" =~ ^https?:// ]]; then
    echo "$download_url"
  else
    echo "https://extensions.gnome.org${download_url}"
  fi
}

_install_extension_archive() {
  local zip_file="$1"
  gnome-extensions install --force "$zip_file"
}

_enable_extension() {
  local uuid="$1"
  gnome-extensions enable "$uuid" 2> /dev/null || true
}

_download_and_install_extension() {
  local download_url="$1"
  local uuid="$2"
  local name="$3"

  local full_download_url
  full_download_url="$(_resolve_extension_url "$download_url")"

  local tmp_zip
  tmp_zip="$(mktemp /tmp/gnome_ext_XXXXXX.zip)"
  if download_file "$full_download_url" "$tmp_zip"; then
    _install_extension_archive "$tmp_zip"
    _enable_extension "$uuid"
    rm -f "$tmp_zip"
    echo "  Successfully installed and enabled '$name'."
  else
    echo "  Failed to download extension package for '$name'."
    rm -f "$tmp_zip"
    return 1
  fi
}

_should_update_extension() {
  local local_ver="$1"
  local remote_ver="$2"

  if [ -z "$local_ver" ]; then
    return 0
  fi

  if [ -n "$remote_ver" ] && [ "$local_ver" -ge "$remote_ver" ] 2> /dev/null; then
    return 1
  fi

  return 0
}

_process_extension() {
  local entry="$1"
  local shell_ver="$2"

  local ext_id
  ext_id="$(cut -d: -f1 <<< "$entry")"
  local fallback_uuid
  fallback_uuid="$(cut -d: -f2 <<< "$entry")"
  local name
  name="$(cut -d: -f3 <<< "$entry")"

  echo "Checking extension: $name (ID: $ext_id)..."

  local json_data
  json_data="$(_fetch_extension_api_data "$ext_id" "$shell_ver")"

  if [ -z "$json_data" ] || [ "$json_data" = "null" ]; then
    echo "  Could not fetch metadata from extensions.gnome.org for '$name'. Skipping."
    return 0
  fi

  local uuid
  uuid="$(_parse_api_field "$json_data" "uuid")"
  if [ -z "$uuid" ]; then
    uuid="$fallback_uuid"
  fi

  local remote_ver
  remote_ver="$(_parse_api_field "$json_data" "version")"
  local download_url
  download_url="$(_parse_api_field "$json_data" "download_url")"

  if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
    echo "  Extension '$name' is not available for GNOME Shell $shell_ver. Skipping."
    return 0
  fi

  local local_ver
  local_ver="$(_get_installed_extension_version "$uuid")"

  if [ -n "$local_ver" ] && ! _should_update_extension "$local_ver" "$remote_ver"; then
    echo "  Extension '$name' is already up to date (v$local_ver)."
    _enable_extension "$uuid"
    return 0
  fi

  if [ -n "$local_ver" ]; then
    echo "  Updating '$name' ($local_ver -> ${remote_ver:-latest})..."
  else
    echo "  Installing '$name' (v${remote_ver:-unknown})...."
  fi

  _download_and_install_extension "$download_url" "$uuid" "$name"
}

_get_target_extensions() {
  local extensions=("${COMMON_EXTENSIONS[@]}")
  if is_distro "arch"; then
    extensions+=("${ARCH_EXTENSIONS[@]}")
  fi
  printf "%s\n" "${extensions[@]}"
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ]; then
    echo "Desktop Environment is '$de' (not GNOME). Skipping GNOME extensions setup."
    return 0
  fi

  echo "Setting up GNOME Shell extensions..."

  local shell_ver
  shell_ver="$(_get_gnome_shell_major_version)"
  echo "Detected GNOME Shell major version: $shell_ver"

  local -a target_extensions=()
  mapfile -t target_extensions < <(_get_target_extensions)

  for entry in "${target_extensions[@]}"; do
    [ -n "$entry" ] || continue
    _process_extension "$entry" "$shell_ver"
  done

  echo "GNOME extensions setup completed successfully."
  echo "Note: If you are running a Wayland session, please log out and log back in for new extensions to take effect."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
