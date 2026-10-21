#!/bin/bash

# System and Hardware Detection Utilities
# Handles OS distribution identification, hardware discovery (GPU),
# root filesystem detection, and user shell profile resolution.

get_distro_id() {
  local os_release_file="${OS_RELEASE_PATH:-/etc/os-release}"
  if [ ! -f "$os_release_file" ] && [ -f /usr/lib/os-release ]; then
    os_release_file="/usr/lib/os-release"
  fi

  if [ -f "$os_release_file" ]; then
    local distro_id
    distro_id="$(grep '^ID=' "$os_release_file" 2> /dev/null | head -n 1 | cut -d= -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]' || true)"

    if [ -n "$distro_id" ]; then
      echo "$distro_id"
      return 0
    fi
  fi

  if command -v lsb_release > /dev/null 2>&1; then
    local lsb_id
    lsb_id="$(lsb_release -si 2> /dev/null | tr '[:upper:]' '[:lower:]' || true)"
    if [ -n "$lsb_id" ]; then
      echo "$lsb_id"
      return 0
    fi
  fi

  echo "unknown"
  return 1
}

is_distro() {
  local target="$1"
  local current
  current="$(get_distro_id 2> /dev/null || echo "unknown")"
  if [ "$target" = "opensuse" ]; then
    case "$current" in
      opensuse*) return 0 ;;
      *) return 1 ;;
    esac
  fi
  [ "$current" = "$target" ]
}

# Validates and returns the current distro if it is one of: debian, fedora, arch, opensuse (leap/tumbleweed).
# Prints the distro ID to stdout on success; prints error and returns 1 on failure.
# Usage: distro="$(require_supported_distro)" || return 1
require_supported_distro() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }
  case "$distro" in
    debian | fedora | arch | opensuse | opensuse-leap | opensuse-tumbleweed)
      echo "$distro"
      return 0
      ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac
}

get_repo_root() {
  if [ -n "${REPO_ROOT_DIR:-}" ] && [ -d "$REPO_ROOT_DIR" ]; then
    echo "$REPO_ROOT_DIR"
    return 0
  fi

  local current_dir
  current_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

  local candidate
  for candidate in \
    "$(cd "$current_dir/../.." 2> /dev/null && pwd || true)" \
    "$(cd "$current_dir/.." 2> /dev/null && pwd || true)" \
    "/setup" \
    "$(pwd)"; do
    if [ -n "$candidate" ] && [ -f "$candidate/main.sh" ] && [ -d "$candidate/scripts" ]; then
      echo "$candidate"
      return 0
    fi
  done

  if [ -d "/setup" ]; then
    echo "/setup"
    return 0
  fi

  pwd
}

get_root_filesystem() {
  findmnt -n -o FSTYPE / 2> /dev/null || df -T / 2> /dev/null | awk 'NR==2 {print $2}' || echo "unknown"
}

# Sets or updates a key=value pair inside a given [section] in an INI or desktop file.
# Preserves surrounding formatting and creates missing sections or files cleanly.
# Usage: write_ini_key <file> <section> <key> <value>
write_ini_key() {
  local file="$1"
  local section="$2"
  local key="$3"
  local val="$4"

  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || touch "$file"

  # Values are passed via ENVIRON so awk does not interpret backslash escape sequences
  INI_VALUE="$val" awk -v sec="[$section]" -v k="$key" '
    BEGIN { v = ENVIRON["INI_VALUE"]; in_sec = 0; replaced = 0; sec_seen = 0; has_lines = 0 }
    /^\[.*\]$/ {
      if (in_sec && !replaced) { print k "=" v; replaced = 1 }
      if ($0 == sec) { in_sec = 1; sec_seen = 1 } else { in_sec = 0 }
    }
    {
      has_lines = 1
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == "") { last_line_blank = 1 } else { last_line_blank = 0 }
      if (in_sec && substr(line, 1, length(k) + 1) == (k "=")) {
        print k "=" v
        replaced = 1
        next
      }
      print
    }
    END {
      if (in_sec && !replaced) { print k "=" v; replaced = 1 }
      if (!sec_seen) {
        if (has_lines && !last_line_blank) { print "" }
        print sec
        print k "=" v
      }
    }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

get_gpu_vendor() {
  if [ -n "${GPU_VENDOR:-}" ]; then
    echo "$GPU_VENDOR"
    return 0
  fi

  if ! command -v has_nvidia_gpu > /dev/null 2>&1; then
    # shellcheck source=scripts/system/_gpu_utils.sh
    source "$(get_repo_root)/scripts/system/_gpu_utils.sh" 2> /dev/null || true
  fi

  if has_nvidia_gpu; then
    echo "nvidia"
  elif has_amd_gpu; then
    echo "amd"
  elif has_intel_gpu; then
    echo "intel"
  else
    echo "unknown"
  fi
}

get_shell_profile() {
  case "${SHELL##*/}" in
    zsh) echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

# Enables and starts the cron service for the current distribution.
# Usage: enable_cron_service [service_name]  (defaults to the distro cron service)
enable_cron_service() {
  if ! command -v systemctl > /dev/null 2>&1; then
    return 0
  fi

  local service="${1:-}"
  if [ -z "$service" ]; then
    if is_distro debian || is_distro opensuse; then
      service="cron"
    elif is_distro fedora; then
      service="crond"
    else
      service="cronie"
    fi
  fi

  echo "Enabling cron scheduler service..."
  sudo systemctl enable --now "${service}.service" 2> /dev/null || sudo systemctl enable "${service}.service" 2> /dev/null || true
}
