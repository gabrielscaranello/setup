#!/usr/bin/env bats

setup() {
  # Clean up any local mock entries before testing
  mkdir -p "$HOME/.local/share/applications"
}

teardown() {
  # Remove test files if created
  sudo rm -f "/usr/share/applications/bottom.desktop" 2> /dev/null || true
  rm -f "$HOME/.local/share/applications/bottom.desktop" 2> /dev/null || true
  rm -f "$HOME/.local/share/applications/nvim.desktop" 2> /dev/null || true
  rm -f "$HOME/.local/share/applications/btop.desktop" 2> /dev/null || true
}

@test "setup-hide-apps.sh executes cleanly and is idempotent" {
  # Create a temporary desktop entry in /usr/share/applications for one of the APPS
  if sudo touch /usr/share/applications/bottom.desktop 2> /dev/null; then
    echo -e "[Desktop Entry]\nType=Application\nName=Bottom\nExec=bottom\nNoDisplay=false" | sudo tee /usr/share/applications/bottom.desktop > /dev/null
  fi

  run bash /setup/scripts/desktop/setup-hide-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Hiding unwanted desktop applications..." ]]
  [[ "$output" =~ "Desktop applications hidden." ]]

  if [ -f "/usr/share/applications/bottom.desktop" ]; then
    [ -f "$HOME/.local/share/applications/bottom.desktop" ]
    grep -q "NoDisplay=true" "$HOME/.local/share/applications/bottom.desktop"
  fi

  # Idempotent re-run
  run bash /setup/scripts/desktop/setup-hide-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop applications hidden." ]]
}

@test "setup-hide-apps.sh does not hide nvim or btop and unhides existing overrides" {
  echo -e "[Desktop Entry]\nType=Application\nName=Neovim\nExec=nvim\nNoDisplay=true" > "$HOME/.local/share/applications/nvim.desktop"
  echo -e "[Desktop Entry]\nType=Application\nName=btop\nExec=btop\nNoDisplay=true" > "$HOME/.local/share/applications/btop.desktop"

  run bash /setup/scripts/desktop/setup-hide-apps.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/applications/nvim.desktop" ]
  [ ! -f "$HOME/.local/share/applications/btop.desktop" ]
}
