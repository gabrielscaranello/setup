#!/bin/bash
set -euo pipefail

# Source utilities
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_setup_fedora_repos() {
  add_fedora_rpmfusion_repo
}

_install_codec_packages() {
  # Install multimedia packages using cross-distro abstraction
  install_packages ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-ugly \
    gstreamer-libav \
    codec-openh264
}

main() {
  local distro
  distro="$(get_distro_id)"

  if [ "$distro" = "unknown" ]; then
    echo "Unsupported distribution for codecs setup." >&2
    exit 1
  fi

  echo "Installing Multimedia Codecs & A/V Plugins..."

  if [ "$distro" = "fedora" ]; then
    _setup_fedora_repos
  fi

  _install_codec_packages

  echo "Codecs installed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
