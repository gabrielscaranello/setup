#!/usr/bin/env bats

setup() {
  # Clean up any local mock entries before testing
  mkdir -p "$HOME/.local/share/applications"
}

teardown() {
  # Remove test file if created
  sudo rm -f "/usr/share/applications/test-setup-hide-apps.desktop" 2> /dev/null || true
  rm -f "$HOME/.local/share/applications/test-setup-hide-apps.desktop" 2> /dev/null || true
}

@test "setup-hide-apps.sh executes cleanly and is idempotent" {
  # Create a temporary desktop entry in /usr/share/applications for one of the APPS
  if sudo touch /usr/share/applications/nvim.desktop 2> /dev/null; then
    echo -e "[Desktop Entry]\nType=Application\nName=Neovim\nExec=nvim\nNoDisplay=false" | sudo tee /usr/share/applications/nvim.desktop > /dev/null
  fi

  run bash /setup/scripts/desktop/setup-hide-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Hiding unwanted desktop applications..." ]]
  [[ "$output" =~ "Desktop applications hidden." ]]

  if [ -f "/usr/share/applications/nvim.desktop" ]; then
    [ -f "$HOME/.local/share/applications/nvim.desktop" ]
    grep -q "NoDisplay=true" "$HOME/.local/share/applications/nvim.desktop"
  fi

  # Idempotent re-run
  run bash /setup/scripts/desktop/setup-hide-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop applications hidden." ]]
}
