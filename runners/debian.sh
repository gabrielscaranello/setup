#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

run_all() {
  local steps=(
    "${COMMON_INITIAL_STEPS[@]}"
    "system/setup-timeshift.sh:Timeshift setup"
    "system/debian/setup-kernel.sh:Debian backports kernel setup"
    "${COMMON_POST_STEPS[@]}"
  )

  run_pipeline "Debian Desktop Setup" "${steps[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
