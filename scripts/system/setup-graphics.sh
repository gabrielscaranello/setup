#!/bin/bash
set -euo pipefail

# Graphics Drivers Orchestrator Script (graphics)
# Sequentially configures NVIDIA and AMD graphics drivers based on hardware detection.

source "scripts/_utils.sh" 2> /dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

_setup_graphics() {
  echo "Applying graphics drivers setup (NVIDIA / AMD)..."
  local system_dir
  system_dir="$(get_repo_root)/scripts/system"

  bash "${system_dir}/setup-nvidia.sh" || return 1
  bash "${system_dir}/setup-amd.sh" || return 1

  echo "Graphics drivers setup completed successfully."
}

main() {
  _setup_graphics
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
