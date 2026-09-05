#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2>/dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/fedora/_repositories.sh" 2>/dev/null || true

main() {
  local distro
  distro=$(get_distro_id)

  if [ "$distro" = "unknown" ]; then
    echo "Unsupported distribution for codecs setup." >&2
    exit 1
  fi

  echo "Installing Multimedia Codecs & A/V Plugins..."

  if [ "$distro" = "fedora" ]; then
    add_fedora_rpmfusion_repo
  fi

  # Install multimedia packages using cross-distro abstraction
  install_packages ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-ugly \
    gstreamer-libav \
    codec-openh264

  echo "Codecs installed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
