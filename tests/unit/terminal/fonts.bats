#!/usr/bin/env bats

# Unit tests for setup-fonts.sh logic and branches

@test "_is_font_installed returns true when font files exist in ~/.fonts" {
  source /setup/scripts/terminal/setup-fonts.sh
  local test_fonts_dir="/tmp/test-fonts-home"
  mkdir -p "$test_fonts_dir"
  touch "$test_fonts_dir/JetBrainsMonoNerdFont-Regular.ttf"

  TARGET_DIR="$test_fonts_dir" run _is_font_installed
  [ "$status" -eq 0 ]
}

@test "_is_font_installed returns true when fc-list reports font" {
  source /setup/scripts/terminal/setup-fonts.sh
  TARGET_DIR="/nonexistent-dir"
  command() {
    if [ "${2:-}" = "fc-list" ]; then return 0; fi
    builtin command "$@"
  }
  fc-list() {
    echo "JetBrainsMono Nerd Font"
    return 0
  }
  run _is_font_installed
  [ "$status" -eq 0 ]
}

@test "_is_font_installed returns false when font is not found" {
  source /setup/scripts/terminal/setup-fonts.sh
  TARGET_DIR="/nonexistent-dir"
  command() {
    if [ "${2:-}" = "fc-list" ]; then return 1; fi
    builtin command "$@"
  }
  run _is_font_installed
  [ "$status" -eq 1 ]
}

@test "_install_fonts_from_upstream skips installation when font is already installed" {
  source /setup/scripts/terminal/setup-fonts.sh
  _is_font_installed() { return 0; }
  run _install_fonts_from_upstream
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed, skipping" ]]
}

@test "_install_fonts_from_upstream uses wget when curl is absent" {
  source /setup/scripts/terminal/setup-fonts.sh
  _is_font_installed() { return 1; }
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    if [ "${2:-}" = "fc-cache" ]; then return 1; fi
    builtin command "$@"
  }
  wget() { return 0; }
  unzip() { return 0; }
  run _install_fonts_from_upstream
  [ "$status" -eq 0 ]
}

@test "_install_fonts fails when distribution is unsupported" {
  source /setup/scripts/terminal/setup-fonts.sh
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_fonts
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_copy_jetbrains_mono_fonts copies ttf files to target directory" {
  source /setup/scripts/terminal/setup-fonts.sh
  local test_work="/tmp/test_work_fonts_$$"
  local test_target="/tmp/test_target_fonts_$$"
  mkdir -p "$test_work"
  touch "$test_work/JetBrainsMonoNerdFont-Regular.ttf"
  touch "$test_work/JetBrainsMonoNerdFont-Bold.ttf"

  TARGET_DIR="$test_target" run _copy_jetbrains_mono_fonts "$test_work"
  [ "$status" -eq 0 ]
  [ -f "$test_target/JetBrainsMonoNerdFont-Regular.ttf" ]
  [ -f "$test_target/JetBrainsMonoNerdFont-Bold.ttf" ]

  rm -rf "$test_work" "$test_target"
}

@test "_update_font_cache calls fc-cache when available" {
  source /setup/scripts/terminal/setup-fonts.sh
  fc-cache() {
    echo "called fc-cache with: $*"
    return 0
  }
  command() { return 0; }

  TARGET_DIR="/tmp/fonts" run _update_font_cache
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Updating font cache" ]]
}

