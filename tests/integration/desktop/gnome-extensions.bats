#!/usr/bin/env bats

setup() {
  # Provide mock gnome-shell and gnome-extensions in test container if full desktop environment is absent
  mkdir -p /tmp/mock_bin
  if ! command -v gnome-shell > /dev/null 2>&1; then
    cat << 'MOCK_EOF' > /tmp/mock_bin/gnome-shell
#!/bin/bash
echo "GNOME Shell 47.0"
MOCK_EOF
    chmod +x /tmp/mock_bin/gnome-shell
  fi

  if ! command -v gnome-extensions > /dev/null 2>&1; then
    cat << 'MOCK_EOF' > /tmp/mock_bin/gnome-extensions
#!/bin/bash
if [ "$1" = "install" ]; then
  # Simulate successful install by creating metadata.json in user extensions dir
  exit 0
elif [ "$1" = "enable" ]; then
  exit 0
fi
exit 0
MOCK_EOF
    chmod +x /tmp/mock_bin/gnome-extensions
  fi
  export PATH="/tmp/mock_bin:$PATH"
}

teardown() {
  rm -rf /tmp/mock_bin
}

@test "setup-gnome-extensions.sh completes gracefully when DE is not GNOME" {
  run bash /setup/scripts/desktop/setup-gnome-extensions.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping GNOME extensions setup." ]]
}

@test "setup-gnome-extensions.sh fails fast when DE is GNOME but gnome-shell is not found" {
  export XDG_CURRENT_DESKTOP="GNOME"
  local saved_path="$PATH"
  export PATH="/usr/bin:/bin" # Ensure mock_bin is not in PATH

  if ! command -v gnome-shell > /dev/null 2>&1; then
    run bash /setup/scripts/desktop/setup-gnome-extensions.sh
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error: gnome-shell is not installed or not found in PATH." ]]
  fi
  export PATH="$saved_path"
}

@test "setup-gnome-extensions.sh runs when DE is GNOME and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-gnome-extensions.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up GNOME Shell extensions..." ]]
  [[ "$output" =~ "Detected GNOME Shell major version: 47" ]]
  [[ "$output" =~ "GNOME extensions setup completed successfully." ]]

  # Idempotency: second run succeeds cleanly
  run bash /setup/scripts/desktop/setup-gnome-extensions.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GNOME extensions setup completed successfully." ]]
}
