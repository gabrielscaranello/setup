#!/bin/bash

# Desktop KDE Plasma 6 helper functions (Facade Pattern)
# Aggregates modular Plasma utilities across configuration I/O, favorites cleanup,
# panel layout, and workspace preferences while preserving backwards compatibility.

_PLASMA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/plasma"
if [ ! -d "$_PLASMA_DIR" ] && [ -d "/setup/scripts/desktop/plasma" ]; then
  _PLASMA_DIR="/setup/scripts/desktop/plasma"
fi

# shellcheck source=scripts/desktop/plasma/_plasma_config.sh
source "${_PLASMA_DIR}/_plasma_config.sh" 2> /dev/null || true
# shellcheck source=scripts/desktop/plasma/_plasma_favorites.sh
source "${_PLASMA_DIR}/_plasma_favorites.sh" 2> /dev/null || true
# shellcheck source=scripts/desktop/plasma/_plasma_panel.sh
source "${_PLASMA_DIR}/_plasma_panel.sh" 2> /dev/null || true
# shellcheck source=scripts/desktop/plasma/_plasma_preferences.sh
source "${_PLASMA_DIR}/_plasma_preferences.sh" 2> /dev/null || true
