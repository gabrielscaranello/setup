#!/bin/bash

# Main utility facade (Facade Pattern)
# Aggregates modular utilities across system, packaging, desktop environment,
# download/releases, and terminal integration domains while preserving backwards compatibility.

_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils"
if [ ! -d "$_UTILS_DIR" ] && [ -d "/setup/scripts/utils" ]; then
  _UTILS_DIR="/setup/scripts/utils"
fi

# shellcheck source=scripts/utils/_system.sh
source "${_UTILS_DIR}/_system.sh" 2> /dev/null || true
# shellcheck source=scripts/utils/_packages.sh
source "${_UTILS_DIR}/_packages.sh" 2> /dev/null || true
# shellcheck source=scripts/utils/_desktop.sh
source "${_UTILS_DIR}/_desktop.sh" 2> /dev/null || true
# shellcheck source=scripts/utils/_download.sh
source "${_UTILS_DIR}/_download.sh" 2> /dev/null || true
# shellcheck source=scripts/utils/_terminal.sh
source "${_UTILS_DIR}/_terminal.sh" 2> /dev/null || true
