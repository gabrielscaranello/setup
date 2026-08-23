#!/usr/bin/env bats

# Integration tests for setup-kitty.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-kitty.sh
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
  run bash /setup/scripts/setup-kitty.sh
  [ "$status" -eq 0 ]
}
