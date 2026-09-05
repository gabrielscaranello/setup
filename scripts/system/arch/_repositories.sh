#!/bin/bash

# Arch Linux-specific repository helper functions (sourced as utility, not executed directly)

add_arch_multilib_repo() {
  local conf="${PACMAN_CONF:-/etc/pacman.conf}"
  if [ ! -f "$conf" ]; then
    return 0
  fi

  if grep -q "^\[multilib\]" "$conf" 2>/dev/null; then
    return 0
  fi

  echo "Enabling multilib repository in $conf..."
  if grep -q "^#[[:space:]]*\[multilib\]" "$conf" 2>/dev/null; then
    sudo sed -i '/^#[[:space:]]*\[multilib\]/{s/^#[[:space:]]*//;n;s/^#[[:space:]]*//}' "$conf"
  else
    cat <<'EOF' | sudo tee -a "$conf" >/dev/null

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  fi

  echo "Updating pacman database..."
  sudo pacman -Sy --noconfirm 2>/dev/null || sudo pacman -Sy
}
