#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-icon-theme.sh
  sudo rm -rf "/usr/share/icons/$THEME_NAME" /usr/local/bin/papirus-folders 2> /dev/null || true
}

teardown() {
  sudo rm -rf "/usr/share/icons/$THEME_NAME" /usr/local/bin/papirus-folders 2> /dev/null || true
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not GNOME). Skipping icon theme setup." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'plasma' (not GNOME). Skipping icon theme setup." ]]
}

@test "main proceeds when desktop environment is gnome" {
  get_desktop_environment() { echo "gnome"; }
  _is_icon_theme_installed() { return 0; }
  _is_system_icon_package_installed() { return 0; }
  _ensure_papirus_folders() { echo "ensured papirus folders"; }
  _apply_papirus_folders_color() { echo "applied folder color"; }
  _configure_gnome_icon_theme() { echo "configured gnome icon theme"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Papirus-Dark icon theme for GNOME..." ]]
  [[ "$output" =~ "Icon theme 'Papirus-Dark' is managed by system package manager." ]]
  [[ "$output" =~ "ensured papirus folders" ]]
  [[ "$output" =~ "applied folder color" ]]
  [[ "$output" =~ "configured gnome icon theme" ]]
  [[ "$output" =~ "Icon theme setup completed successfully." ]]
}

@test "_is_icon_theme_installed returns 0 when theme directory exists" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"
  mkdir -p "$HOME/.local/share/icons/Papirus-Dark"

  run _is_icon_theme_installed
  [ "$status" -eq 0 ]
  rm -rf "$mock_home"
}

@test "_is_icon_theme_installed returns 1 when theme directory does not exist" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _is_icon_theme_installed
  [ "$status" -eq 1 ]
  rm -rf "$mock_home"
}

@test "_install_icon_package delegates to install_packages" {
  install_packages() {
    echo "packages installed: $*"
  }

  run _install_icon_package
  [ "$status" -eq 0 ]
  [[ "$output" =~ "packages installed: papirus-icon-theme" ]]
}

@test "_is_papirus_folders_installed checks command availability" {
  command() { return 0; }
  run _is_papirus_folders_installed
  [ "$status" -eq 0 ]
}

@test "_install_papirus_folders_upstream downloads and installs script" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  download_file() {
    touch "$2"
  }
  sudo() { :; }

  run _install_papirus_folders_upstream
  [ "$status" -eq 0 ]
  rm -rf "$mock_home"
}

@test "_is_system_icon_package_installed checks package manager" {
  get_distro_id() { echo "debian"; }
  dpkg() { return 0; }
  run _is_system_icon_package_installed
  [ "$status" -eq 0 ]

  get_distro_id() { echo "fedora"; }
  rpm() { return 0; }
  run _is_system_icon_package_installed
  [ "$status" -eq 0 ]

  get_distro_id() { echo "arch"; }
  pacman() { return 0; }
  run _is_system_icon_package_installed
  [ "$status" -eq 0 ]
}

@test "_ensure_icon_theme reports managed by system package manager" {
  _is_icon_theme_installed() { return 0; }
  _is_system_icon_package_installed() { return 0; }

  run _ensure_icon_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Icon theme 'Papirus-Dark' is managed by system package manager." ]]
}

@test "_get_local_papirus_folders_version parses version correctly" {
  papirus-folders() {
    echo "papirus-folders 1.14.0"
  }

  run _get_local_papirus_folders_version
  [ "$status" -eq 0 ]
  [ "$output" = "1.14.0" ]
}

@test "_fetch_remote_papirus_folders_version extracts tag_name" {
  fetch_url() {
    echo '{"tag_name": "v1.14.0"}'
  }

  run _fetch_remote_papirus_folders_version
  [ "$status" -eq 0 ]
  [ "$output" = "v1.14.0" ]
}

@test "_is_system_papirus_folders_installed checks pacman on Arch" {
  get_distro_id() { echo "arch"; }
  pacman() { return 0; }
  run _is_system_papirus_folders_installed
  [ "$status" -eq 0 ]

  get_distro_id() { echo "debian"; }
  run _is_system_papirus_folders_installed
  [ "$status" -eq 1 ]
}

@test "_ensure_papirus_folders updates when newer upstream release exists" {
  command() { return 0; }
  _is_system_papirus_folders_installed() { return 1; }
  _get_local_papirus_folders_version() { echo "1.13.0"; }
  _fetch_remote_papirus_folders_version() { echo "v1.14.0"; }
  _install_papirus_folders_upstream() { echo "updated to $1"; }

  run _ensure_papirus_folders
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Updating papirus-folders from GitHub (1.13.0 -> v1.14.0)..." ]]
  [[ "$output" =~ "updated to v1.14.0" ]]
}

@test "_ensure_papirus_folders skips update when already up to date" {
  command() { return 0; }
  _is_system_papirus_folders_installed() { return 1; }
  _get_local_papirus_folders_version() { echo "1.14.0"; }
  _fetch_remote_papirus_folders_version() { echo "v1.14.0"; }
  _install_papirus_folders_upstream() {
    echo "SHOULD NOT BE CALLED"
    return 1
  }

  run _ensure_papirus_folders
  [ "$status" -eq 0 ]
  [[ "$output" =~ "papirus-folders is up to date (1.14.0)." ]]
}

@test "_ensure_papirus_folders recognizes system package manager" {
  command() { return 0; }
  _is_system_papirus_folders_installed() { return 0; }

  run _ensure_papirus_folders
  [ "$status" -eq 0 ]
  [[ "$output" =~ "papirus-folders is managed by system package manager." ]]
}

@test "_ensure_papirus_folders delegates to install_packages on Arch Linux when not installed" {
  command() { return 1; }
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "packages installed: $*"
  }

  run _ensure_papirus_folders
  [ "$status" -eq 0 ]
  [[ "$output" =~ "packages installed: papirus-folders" ]]
}

@test "_ensure_papirus_folders delegates to upstream on Debian and Fedora when not installed" {
  command() { return 1; }
  get_distro_id() { echo "debian"; }
  _install_papirus_folders_upstream() {
    echo "called upstream installer"
  }

  run _ensure_papirus_folders
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called upstream installer" ]]
}

@test "_apply_papirus_folders_color invokes papirus-folders with adwaita" {
  papirus-folders() {
    echo "papirus-folders called: $*"
  }

  run _apply_papirus_folders_color
  [ "$status" -eq 0 ]
  [[ "$output" =~ "papirus-folders called: -C adwaita" ]]
}

@test "_configure_gnome_icon_theme invokes gsettings" {
  gsettings() {
    echo "gsettings called: $*"
  }

  run _configure_gnome_icon_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.interface icon-theme Papirus-Dark" ]]
}
