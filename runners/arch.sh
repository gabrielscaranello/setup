#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/_utils.sh" 2> /dev/null || true

_ensure_target_de() {
  local de
  de="$(ensure_desktop_environment "Selecione o Desktop Environment para a instalação no Arch Linux:")"
  echo "Desktop Environment configurado para a execução: $de"
}

run_all() {
  _ensure_target_de
  local steps=(
    "${COMMON_INITIAL_STEPS[@]}"
    "system/arch/setup-desktop-environment.sh:Desktop environment setup"
    "system/setup-timeshift.sh:Timeshift setup"
    "${COMMON_POST_STEPS[@]}"
  )

  run_pipeline "Arch Linux Desktop Setup" "${steps[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
