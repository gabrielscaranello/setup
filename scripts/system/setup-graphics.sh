#!/bin/bash
set -euo pipefail

# Graphics Drivers Orchestrator Script (graphics)
# Sequentially configures NVIDIA and AMD graphics drivers based on hardware detection.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/setup-nvidia.sh" ] && [ -d "/setup/scripts/system" ]; then
  SCRIPT_DIR="/setup/scripts/system"
elif [ ! -f "${SCRIPT_DIR}/setup-nvidia.sh" ] && [ -d "scripts/system" ]; then
  SCRIPT_DIR="$(pwd)/scripts/system"
fi

source "${SCRIPT_DIR}/../_utils.sh" 2> /dev/null || true

_setup_graphics() {
  echo "Applying graphics drivers setup (NVIDIA / AMD)..."

  bash "${SCRIPT_DIR}/setup-nvidia.sh" || return 1
  bash "${SCRIPT_DIR}/setup-amd.sh" || return 1

  echo "Graphics drivers setup completed successfully."
}

main() {
  _setup_graphics
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
