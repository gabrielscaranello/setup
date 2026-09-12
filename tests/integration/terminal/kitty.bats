#!/usr/bin/env bats

# Integration tests for setup-kitty.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/terminal/setup-kitty.sh
}

@test "kitty binary is available and executable" {
  if command -v kitty >/dev/null 2>&1; then
    run kitty --version
    [ "$status" -eq 0 ]
  elif [ -x "$HOME/.local/bin/kitty" ]; then
    run "$HOME/.local/bin/kitty" --version
    [ "$status" -eq 0 ]
  elif [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    run "$HOME/.local/kitty.app/bin/kitty" --version
    [ "$status" -eq 0 ]
  else
    false
  fi
}

@test "setup-kitty.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/terminal/setup-kitty.sh
  [ "$status" -eq 0 ]
}

@test "x-terminal-emulator is available and executable" {
  if command -v x-terminal-emulator >/dev/null 2>&1; then
    run x-terminal-emulator --version
    [ "$status" -eq 0 ]
  elif [ -x "$HOME/.local/bin/x-terminal-emulator" ]; then
    run "$HOME/.local/bin/x-terminal-emulator" --version
    [ "$status" -eq 0 ]
  elif [ -x "/usr/local/bin/x-terminal-emulator" ]; then
    run "/usr/local/bin/x-terminal-emulator" --version
    [ "$status" -eq 0 ]
  else
    false
  fi
}
