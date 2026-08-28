#!/usr/bin/env bats

# Integration tests for setup-fonts.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/terminal/setup-fonts.sh
}

@test "JetBrains Mono Nerd Font files or system font entry is present" {
  if [ -d "$HOME/.fonts" ] && ls "$HOME/.fonts"/JetBrainsMonoNerdFont*.ttf >/dev/null 2>&1; then
    true
  elif ls /usr/share/fonts/TTF/JetBrainsMono*.ttf >/dev/null 2>&1 || ls /usr/share/fonts/*/JetBrainsMono*.ttf >/dev/null 2>&1; then
    true
  elif command -v fc-list >/dev/null 2>&1 && fc-list : family | grep -qi "JetBrainsMono"; then
    true
  else
    false
  fi
}

@test "setup-fonts.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/terminal/setup-fonts.sh
  [ "$status" -eq 0 ]
}
