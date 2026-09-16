#!/bin/bash
set -euo pipefail

# Desktop Appearance Orchestrator Script (look)
# Sequentially configures cursor theme, GTK theme, and icon theme.

source "scripts/_utils.sh" 2> /dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

_setup_look() {
  echo "Applying desktop appearance setup (cursor, GTK theme, icon theme)..."
  local desktop_dir
  desktop_dir="$(get_repo_root)/scripts/desktop"

  bash "${desktop_dir}/setup-cursor-theme.sh" || return 1
  bash "${desktop_dir}/setup-gtk-theme.sh" || return 1
  bash "${desktop_dir}/setup-icon-theme.sh" || return 1

  echo "Desktop appearance setup completed successfully."
}

main() {
  _setup_look
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
