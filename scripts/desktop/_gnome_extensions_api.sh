#!/bin/bash
set -euo pipefail

# GNOME Shell Extensions API & Metadata Client
# Provides helper functions for querying extensions.gnome.org API,
# extracting extension metadata, and version comparison.

# Source core utilities if not already loaded
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

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

  if command -v jq > /dev/null 2>&1; then
    jq -r --arg f "$field" '.[$f] // empty' <<< "$json_str" 2> /dev/null || true
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
