#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_python() {
  require_supported_distro > /dev/null || return 1

  echo "Installing Python 3, pip and venv from distribution repository..."
  install_packages python3 python-pip python-venv
}

main() {
  echo "Setting up Python..."
  _install_python
  echo "setup-python complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
