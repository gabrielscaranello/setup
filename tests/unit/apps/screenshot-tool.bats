#!/usr/bin/env bats

# Unit tests for setup-screenshot.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-screenshot-tool.sh
}

@test "_install_screenshot_tool fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run _install_screenshot_tool
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_screenshot_tool installs flameshot on GNOME" {
  require_supported_distro() { echo "arch"; }
  get_desktop_environment() { echo "gnome"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: flameshot" ]]
}

@test "_install_screenshot_tool installs spectacle on KDE Plasma" {
  require_supported_distro() { echo "fedora"; }
  get_desktop_environment() { echo "plasma"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: spectacle" ]]
}

@test "_install_screenshot_tool skips and does nothing on unknown desktop environment" {
  require_supported_distro() { echo "debian"; }
  get_desktop_environment() { echo "unknown"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unrecognized desktop environment: unknown. Skipping screenshot tool setup." ]]
  [[ ! "$output" =~ "installed packages" ]]
}

@test "_install_screenshot_tool installs flameshot and configures shortcuts on Cinnamon" {
  require_supported_distro() { echo "lmde"; }
  get_desktop_environment() { echo "cinnamon"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  _configure_cinnamon_shortcuts() {
    echo "cinnamon shortcuts configured"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Flameshot for Cinnamon..." ]]
  [[ "$output" =~ "installed packages: flameshot" ]]
  [[ "$output" =~ "cinnamon shortcuts configured" ]]
}

@test "_configure_cinnamon_shortcuts skips if dconf is missing and ensure_dconf is unavailable" {
  command() {
    if [ "$1" = "-v" ] && { [ "$2" = "dconf" ] || [ "$2" = "ensure_dconf" ]; }; then
      return 1
    fi
    builtin command "$@"
  }
  run _configure_cinnamon_shortcuts
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf not found. Skipping Cinnamon shortcut configuration." ]]
}

@test "_configure_cinnamon_shortcuts calls ensure_dconf when dconf is not in PATH" {
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "dconf" ]; then
      return 1
    fi
    builtin command "$@"
  }
  ensure_dconf() {
    echo "ensure_dconf called"
    return 1
  }
  run _configure_cinnamon_shortcuts
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ensure_dconf called" ]]
}

@test "_configure_cinnamon_shortcuts sets up custom0 when custom-list is empty" {
  command() {
    builtin command "$@"
  }
  dconf_exec() {
    case "$1" in
      read)
        if [ "$2" = "/org/cinnamon/desktop/keybindings/custom-list" ]; then
          echo "@as []"
        else
          return 1
        fi
        ;;
      write)
        echo "write: $2 -> $3"
        ;;
    esac
  }
  run _configure_cinnamon_shortcuts
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Flameshot shortcuts for Cinnamon..." ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-list -> ['custom0']" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name -> 'Flameshot'" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command -> 'flameshot gui'" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding -> ['Print', '<Primary><Alt>s']" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/media-keys/screenshot -> @as []" ]]
}

@test "_configure_cinnamon_shortcuts reuses existing slot if flameshot is already configured" {
  command() {
    builtin command "$@"
  }
  dconf_exec() {
    case "$1" in
      read)
        if [ "$2" = "/org/cinnamon/desktop/keybindings/custom-list" ]; then
          echo "['custom0']"
        elif [ "$2" = "/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command" ]; then
          echo "'flameshot gui'"
        fi
        ;;
      write)
        echo "write: $2 -> $3"
        ;;
    esac
  }
  run _configure_cinnamon_shortcuts
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Flameshot shortcuts for Cinnamon..." ]]
  [[ ! "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-list" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name -> 'Flameshot'" ]]
}

@test "_configure_cinnamon_shortcuts appends custom1 if custom0 is occupied by another app" {
  command() {
    builtin command "$@"
  }
  dconf_exec() {
    case "$1" in
      read)
        if [ "$2" = "/org/cinnamon/desktop/keybindings/custom-list" ]; then
          echo "['custom0']"
        elif [ "$2" = "/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command" ]; then
          echo "'gedit'"
        fi
        ;;
      write)
        echo "write: $2 -> $3"
        ;;
    esac
  }
  run _configure_cinnamon_shortcuts
  [ "$status" -eq 0 ]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-list -> ['custom0', 'custom1']" ]]
  [[ "$output" =~ "write: /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name -> 'Flameshot'" ]]
}

@test "main executes _install_screenshot_tool" {
  _install_screenshot_tool() {
    echo "mocked _install_screenshot_tool"
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mocked _install_screenshot_tool" ]]
  [[ "$output" =~ "setup-screenshot complete" ]]
}
