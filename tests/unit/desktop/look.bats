#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/desktop/setup-look.sh

setup() {
  source /setup/scripts/desktop/setup-look.sh 2> /dev/null || source scripts/desktop/setup-look.sh
}

@test "_setup_look runs cursor, gtk-theme, and icon-theme scripts in order" {
  bash() {
    echo "called: $(basename "$1")"
    return 0
  }

  run _setup_look
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying desktop appearance setup" ]]
  [[ "$output" =~ "called: setup-cursor-theme.sh" ]]
  [[ "$output" =~ "called: setup-gtk-theme.sh" ]]
  [[ "$output" =~ "called: setup-icon-theme.sh" ]]
  [[ "$output" =~ "Desktop appearance setup completed successfully." ]]
}

@test "_setup_look propagates failure if cursor theme setup fails" {
  bash() {
    if [[ "$1" =~ setup-cursor-theme\.sh$ ]]; then
      return 1
    fi
    return 0
  }

  run _setup_look
  [ "$status" -eq 1 ]
}

@test "_setup_look propagates failure if gtk theme setup fails" {
  bash() {
    if [[ "$1" =~ setup-gtk-theme\.sh$ ]]; then
      return 1
    fi
    return 0
  }

  run _setup_look
  [ "$status" -eq 1 ]
}

@test "_setup_look propagates failure if icon theme setup fails" {
  bash() {
    if [[ "$1" =~ setup-icon-theme\.sh$ ]]; then
      return 1
    fi
    return 0
  }

  run _setup_look
  [ "$status" -eq 1 ]
}

@test "main executes _setup_look successfully" {
  bash() {
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop appearance setup completed successfully." ]]
}
