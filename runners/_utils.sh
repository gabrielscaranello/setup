#!/bin/bash
set -euo pipefail

run_pipeline() {
  local pipeline_name="$1"
  shift
  local steps=("$@")
  local scripts_dir
  scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

  echo "======================================="
  echo "   $pipeline_name Pipeline"
  echo "======================================="
  echo ""

  local step_file step_desc
  for step in "${steps[@]}"; do
    step_file="${step%%:*}"
    step_desc="${step##*:}"
    echo ">>> Running $step_desc..."
    echo ""
    bash "$scripts_dir/$step_file"
    echo ""
    echo "✓ $step_desc completed"
    echo ""
  done

  echo "======================================="
  echo "   $pipeline_name Setup Completed Successfully!"
  echo "======================================="
}
