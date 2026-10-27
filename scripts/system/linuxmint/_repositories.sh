#!/bin/bash

# Linux Mint-specific repository helper functions (sourced as utility, not executed directly)
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || source "scripts/_utils.sh" 2> /dev/null || true

get_linuxmint_base_codename() {
  local codename
  codename="$(get_os_release_field UBUNTU_CODENAME)"
  if [ -z "$codename" ]; then
    codename="$(get_os_release_field VERSION_CODENAME)"
  fi
  if [ -n "$codename" ]; then
    echo "$codename"
    return 0
  fi

  # Fallback to noble (Mint 22 base) if detection fails
  echo "noble"
}
