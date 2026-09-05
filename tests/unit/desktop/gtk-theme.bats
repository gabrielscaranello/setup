#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-gtk-theme.sh
  sudo rm -rf /usr/share/themes/adw-gtk3 /usr/share/themes/adw-gtk3-dark 2> /dev/null || true
}

teardown() {
  sudo rm -rf /usr/share/themes/adw-gtk3 /usr/share/themes/adw-gtk3-dark 2> /dev/null || true
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not GNOME). Skipping GTK theme setup." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'plasma' (not GNOME). Skipping GTK theme setup." ]]
}

@test "main proceeds when desktop environment is gnome and managed by package manager" {
  get_desktop_environment() { echo "gnome"; }
  _is_gtk_theme_installed() { return 0; }
  _is_system_package_installed() { return 0; }
  _install_flatpak_theme() { echo "installed flatpak theme"; }
  _configure_gnome_gtk_theme() { echo "configured gnome theme"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up adw-gtk3-dark GTK theme for GNOME..." ]]
  [[ "$output" =~ "GTK theme 'adw-gtk3-dark' is managed by system package manager." ]]
  [[ "$output" =~ "installed flatpak theme" ]]
  [[ "$output" =~ "configured gnome theme" ]]
  [[ "$output" =~ "GTK theme setup completed successfully." ]]
}

@test "main updates theme when installed via GitHub and newer release exists" {
  get_desktop_environment() { echo "gnome"; }
  _is_gtk_theme_installed() { return 0; }
  _is_system_package_installed() { return 1; }
  _get_local_version() { echo "v6.4"; }
  _fetch_remote_version() { echo "v6.5"; }
  _install_upstream_theme() { echo "updating to $1"; }
  _install_flatpak_theme() { return 0; }
  _configure_gnome_gtk_theme() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Updating GTK theme from GitHub (v6.4 -> v6.5)..." ]]
  [[ "$output" =~ "updating to v6.5" ]]
}

@test "main reports up to date when GitHub installed theme matches latest version" {
  get_desktop_environment() { echo "gnome"; }
  _is_gtk_theme_installed() { return 0; }
  _is_system_package_installed() { return 1; }
  _get_local_version() { echo "v6.5"; }
  _fetch_remote_version() { echo "v6.5"; }
  _install_flatpak_theme() { return 0; }
  _configure_gnome_gtk_theme() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GTK theme 'adw-gtk3-dark' is up to date (v6.5)." ]]
}

@test "_is_gtk_theme_installed returns 0 when both theme directories exist" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"
  mkdir -p "$HOME/.local/share/themes/adw-gtk3-dark"
  mkdir -p "$HOME/.local/share/themes/adw-gtk3"

  run _is_gtk_theme_installed
  [ "$status" -eq 0 ]
  rm -rf "$mock_home"
}

@test "_is_gtk_theme_installed returns 1 when theme directory does not exist or only one exists" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _is_gtk_theme_installed
  [ "$status" -eq 1 ]

  mkdir -p "$HOME/.local/share/themes/adw-gtk3-dark"
  run _is_gtk_theme_installed
  [ "$status" -eq 1 ]

  rm -rf "$mock_home"
}

@test "_install_theme_package delegates to install_packages on Fedora" {
  get_distro_id() { echo "fedora"; }
  install_packages() {
    echo "packages installed: $*"
  }

  run _install_theme_package
  [ "$status" -eq 0 ]
  [[ "$output" =~ "packages installed: adw-gtk3-theme" ]]
}

@test "_install_theme_package delegates to install_packages on Arch Linux" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "packages installed: $*"
  }

  run _install_theme_package
  [ "$status" -eq 0 ]
  [[ "$output" =~ "packages installed: adw-gtk3-theme" ]]
}

@test "_install_theme_package delegates to upstream on Debian" {
  get_distro_id() { echo "debian"; }
  _install_upstream_theme() {
    echo "called upstream installer"
  }

  run _install_theme_package
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called upstream installer" ]]
}

@test "_install_upstream_theme downloads, extracts and writes version file" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  install_packages() { return 0; }
  sudo() { :; }
  fetch_url() { echo '{"tag_name": "v6.5"}'; }
  download_file() { touch "$2"; }
  tar() {
    local target_dir="$4"
    mkdir -p "$target_dir/adw-gtk3" "$target_dir/adw-gtk3-dark"
  }

  run _install_upstream_theme "v6.5"
  [ "$status" -eq 0 ]
  [ -d "$mock_home/.local/share/themes/adw-gtk3-dark" ]
  [ -L "$mock_home/.themes/adw-gtk3-dark" ]
  [ -f "$mock_home/.local/share/themes/adw-gtk3/.version" ]
  [ "$(cat "$mock_home/.local/share/themes/adw-gtk3/.version")" = "v6.5" ]
  rm -rf "$mock_home"
}

@test "_get_local_version reads version file correctly" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "" ]

  mkdir -p "$mock_home/.local/share/themes/adw-gtk3"
  echo "v6.5" > "$mock_home/.local/share/themes/adw-gtk3/.version"

  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "v6.5" ]

  rm -rf "$mock_home"
}

@test "_fetch_remote_version extracts tag_name from GitHub API response" {
  fetch_url() {
    echo '{"tag_name": "v6.5", "name": "Release v6.5"}'
  }

  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "v6.5" ]
}

@test "_is_system_package_installed checks package manager on Fedora and Arch" {
  get_distro_id() { echo "debian"; }
  run _is_system_package_installed
  [ "$status" -eq 1 ]

  get_distro_id() { echo "fedora"; }
  rpm() { return 0; }
  run _is_system_package_installed
  [ "$status" -eq 0 ]

  get_distro_id() { echo "arch"; }
  pacman() { return 0; }
  run _is_system_package_installed
  [ "$status" -eq 0 ]
}

@test "_install_flatpak_theme calls install_flatpak_app when flatpak is available" {
  install_flatpak_app() {
    echo "flatpak app installed: $*"
  }

  run _install_flatpak_theme
  [ "$status" -eq 0 ]
  if command -v flatpak > /dev/null 2>&1; then
    [[ "$output" =~ "flatpak app installed: org.gtk.Gtk3theme.adw-gtk3" ]]
    [[ "$output" =~ "flatpak app installed: org.gtk.Gtk3theme.adw-gtk3-dark" ]]
  fi
}

@test "_configure_gnome_gtk_theme invokes gsettings" {
  gsettings() {
    echo "gsettings called: $*"
  }

  run _configure_gnome_gtk_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.interface gtk-theme adw-gtk3-dark" ]]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.wm.preferences theme adw-gtk3-dark" ]]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.interface color-scheme prefer-dark" ]]
}
