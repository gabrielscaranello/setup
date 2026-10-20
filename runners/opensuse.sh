#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/_utils.sh" 2> /dev/null || true

run_all() {
  ensure_target_de "openSUSE"
  local steps=(
    "${COMMON_INITIAL_STEPS[@]}"
    "system/setup-timeshift.sh:Snapper snapshot and rollback setup"
  )

  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  if [ "$distro" != "opensuse-tumbleweed" ]; then
    steps+=("system/opensuse/setup-kernel.sh:openSUSE Leap latest kernel and headers setup")
  fi

  steps+=("${COMMON_POST_STEPS[@]}")

  run_pipeline "openSUSE Desktop Setup" "${steps[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
