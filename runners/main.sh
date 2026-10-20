#!/bin/bash
set -euo pipefail

RUNNERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

# Source utilities for package manager and distro detection
source "$SCRIPTS_DIR/_utils.sh" 2> /dev/null || true
# shellcheck source=runners/_modules.sh
source "$RUNNERS_DIR/_modules.sh"

# Splits a registry entry into the globals _MOD_NAME, _MOD_ALIASES, _MOD_PATH and _MOD_DESC
_parse_module_entry() {
  IFS='|' read -r _MOD_NAME _MOD_ALIASES _MOD_PATH _MOD_DESC <<< "$1"
}

show_help() {
  cat << 'HELP_EOF'
=======================================
   Desktop Setup - CLI & Orchestrator
=======================================

Usage:
  ./main.sh [command]
  make [command]

Available Commands:
HELP_EOF

  local entry
  printf '  %-23s - %s\n' "help" "Show this help message"
  printf '  %-23s - %s\n' "all" "Run complete desktop setup pipeline for current distribution"
  for entry in "${MODULES[@]}"; do
    _parse_module_entry "$entry"
    printf '  %-23s - %s\n' "$_MOD_NAME" "$_MOD_DESC"
  done
}

run_all() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"

  case "$distro" in
    debian)
      echo "Delegating complete setup to Debian runner..."
      bash "$RUNNERS_DIR/debian.sh"
      ;;

    fedora)
      echo "Delegating complete setup to Fedora runner..."
      bash "$RUNNERS_DIR/fedora.sh"
      ;;

    arch)
      echo "Delegating complete setup to Arch Linux runner..."
      bash "$RUNNERS_DIR/arch.sh"
      ;;

    opensuse | opensuse-leap | opensuse-tumbleweed)
      echo "Delegating complete setup to openSUSE runner..."
      bash "$RUNNERS_DIR/opensuse.sh"
      ;;

    *)
      if [ -n "$distro" ] && [ "$distro" != "unknown" ]; then
        echo "Unsupported distribution: '$distro'. Only 'debian', 'fedora', 'arch', and 'opensuse' are currently supported." >&2
      else
        echo "Unsupported distribution: Unable to detect a supported distribution (debian, fedora, arch, opensuse)." >&2
      fi
      return 1
      ;;
  esac
}

# Resolves a command name (or alias) to its registry entry; returns 1 when unknown
_find_module() {
  local target="$1" entry alias
  local -a aliases
  for entry in "${MODULES[@]}"; do
    _parse_module_entry "$entry"
    if [ "$_MOD_NAME" = "$target" ]; then
      return 0
    fi
    IFS=',' read -r -a aliases <<< "$_MOD_ALIASES"
    for alias in "${aliases[@]}"; do
      if [ "$alias" = "$target" ]; then
        return 0
      fi
    done
  done
  return 1
}

run_module() {
  local target="$1"
  shift

  case "$target" in
    help | --help | -h)
      show_help
      return 0
      ;;
    all)
      run_all
      return 0
      ;;
  esac

  if ! _find_module "$target"; then
    echo "Unknown command: $target" >&2
    echo "" >&2
    show_help >&2
    return 1
  fi

  bash "$REPO_ROOT/$_MOD_PATH" "$@"
}

main() {
  # Setup scripts source helpers via paths relative to the repository root
  cd "$REPO_ROOT" || return 1

  if [ $# -eq 0 ]; then
    show_help
  else
    run_module "$@"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
