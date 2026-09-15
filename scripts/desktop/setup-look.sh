#!/bin/bash
set -euo pipefail

# Desktop Appearance Orchestrator Script (look)
# Sequentially configures cursor theme, GTK theme, and icon theme.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/setup-cursor-theme.sh" ] && [ -d "/setup/scripts/desktop" ]; then
  SCRIPT_DIR="/setup/scripts/desktop"
elif [ ! -f "${SCRIPT_DIR}/setup-cursor-theme.sh" ] && [ -d "scripts/desktop" ]; then
  SCRIPT_DIR="$(pwd)/scripts/desktop"
fi

source "${SCRIPT_DIR}/../_utils.sh" 2> /dev/null || true

_setup_look() {
  echo "Applying desktop appearance setup (cursor, GTK theme, icon theme)..."

  bash "${SCRIPT_DIR}/setup-cursor-theme.sh" || return 1
  bash "${SCRIPT_DIR}/setup-gtk-theme.sh" || return 1
  bash "${SCRIPT_DIR}/setup-icon-theme.sh" || return 1

  echo "Desktop appearance setup completed successfully."
}

main() {
  _setup_look
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
