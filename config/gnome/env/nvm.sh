#!/bin/sh

# shellcheck disable=SC1091

# Init NVM on Login in GNOME

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[ -f /usr/share/nvm/init-nvm.sh ] && \. /usr/share/nvm/init-nvm.sh

if command -v systemctl > /dev/null 2>&1; then
  systemctl --user import-environment PATH NVM_BIN NVM_DIR 2> /dev/null || true
fi

if command -v dbus-update-activation-environment > /dev/null 2>&1; then
  dbus-update-activation-environment --systemd PATH NVM_BIN NVM_DIR 2> /dev/null || true
fi
