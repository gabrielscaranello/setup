#!/bin/bash

# Terminal and XDG Integration Utilities
# Deploys and configures xdg-terminal-exec, x-terminal-emulator, and
# user environment PATH specifications for terminal execution.

# shellcheck disable=SC2016
ensure_xdg_terminal_exec() {
  local user_bin="$HOME/.local/bin"
  mkdir -p "$user_bin"

  local script_content='#!/bin/sh
if [ "${1:-}" = "-e" ] || [ "${1:-}" = "--" ]; then
  shift
fi

if command -v kitty > /dev/null 2>&1; then
  TERMINAL="kitty"
elif [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
  TERMINAL="$HOME/.local/kitty.app/bin/kitty"
elif [ -x "$HOME/.local/bin/kitty" ]; then
  TERMINAL="$HOME/.local/bin/kitty"
else
  TERMINAL="kitty"
fi

if [ "$#" -eq 0 ]; then
  exec "$TERMINAL"
else
  exec "$TERMINAL" "$@"
fi'

  echo "$script_content" > "$user_bin/xdg-terminal-exec"
  chmod 755 "$user_bin/xdg-terminal-exec"
  ln -sf "xdg-terminal-exec" "$user_bin/x-terminal-emulator"
  if [ ! -f "/usr/bin/gnome-terminal" ]; then
    ln -sf "xdg-terminal-exec" "$user_bin/gnome-terminal"
  fi

  if [ -w "/usr/local/bin" ]; then
    echo "$script_content" > "/usr/local/bin/xdg-terminal-exec"
    chmod 755 "/usr/local/bin/xdg-terminal-exec"
    ln -sf "xdg-terminal-exec" "/usr/local/bin/x-terminal-emulator"
    if [ ! -f "/usr/bin/gnome-terminal" ]; then
      ln -sf "xdg-terminal-exec" "/usr/local/bin/gnome-terminal"
    fi
  elif command -v sudo > /dev/null 2>&1; then
    local tmp_script
    tmp_script="$(mktemp)"
    echo "$script_content" > "$tmp_script"
    chmod 755 "$tmp_script"
    sudo cp "$tmp_script" "/usr/local/bin/xdg-terminal-exec" 2> /dev/null || true
    sudo chmod 755 "/usr/local/bin/xdg-terminal-exec" 2> /dev/null || true
    sudo ln -sf "/usr/local/bin/xdg-terminal-exec" "/usr/local/bin/x-terminal-emulator" 2> /dev/null || true
    if [ ! -f "/usr/bin/gnome-terminal" ]; then
      sudo ln -sf "/usr/local/bin/xdg-terminal-exec" "/usr/local/bin/gnome-terminal" 2> /dev/null || true
    fi
    rm -f "$tmp_script"
  fi

  local env_d="$HOME/.config/environment.d"
  mkdir -p "$env_d"
  if [ ! -f "$env_d/10-local-path.conf" ]; then
    echo 'PATH="${HOME}/.local/bin:${PATH}"' > "$env_d/10-local-path.conf"
  fi
}
