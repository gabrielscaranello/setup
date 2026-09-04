#!/usr/bin/env bats

# Unit tests for _utils.sh functions and mappings

setup() {
  source /setup/scripts/_utils.sh
}

@test "_get_package_name resolves build-tools for all managers" {
  [ "$(_get_package_name "build-tools" "apt")" = "build-essential" ]
  [ "$(_get_package_name "build-tools" "dnf")" = "@development-tools" ]
  [ "$(_get_package_name "build-tools" "pacman")" = "base-devel" ]
}

@test "_get_package_name resolves ninja-build for all managers" {
  [ "$(_get_package_name "ninja-build" "pacman")" = "ninja" ]
  [ "$(_get_package_name "ninja-build" "apt")" = "ninja-build" ]
  [ "$(_get_package_name "ninja-build" "dnf")" = "ninja-build" ]
}

@test "_get_package_name resolves gcc-cxx for all managers" {
  [ "$(_get_package_name "gcc-cxx" "apt")" = "g++" ]
  [ "$(_get_package_name "gcc-cxx" "dnf")" = "gcc-c++" ]
  [ "$(_get_package_name "gcc-cxx" "pacman")" = "gcc" ]
}

@test "_get_package_name resolves gettext-tools for all managers" {
  [ "$(_get_package_name "gettext-tools" "dnf")" = "gettext-devel" ]
  [ "$(_get_package_name "gettext-tools" "apt")" = "gettext" ]
  [ "$(_get_package_name "gettext-tools" "pacman")" = "gettext" ]
}

@test "_get_package_name resolves libclang for all managers" {
  [ "$(_get_package_name "libclang" "dnf")" = "clang-devel" ]
  [ "$(_get_package_name "libclang" "apt")" = "libclang-dev" ]
  [ "$(_get_package_name "libclang" "pacman")" = "clang" ]
}

@test "_get_package_name resolves golang for all managers" {
  [ "$(_get_package_name "golang" "dnf")" = "golang" ]
  [ "$(_get_package_name "golang" "apt")" = "golang" ]
  [ "$(_get_package_name "golang" "pacman")" = "go" ]
}

@test "_get_package_name resolves font packages for distros" {
  [ "$(_get_package_name "fonts-jetbrains-mono-nerd" "pacman")" = "ttf-jetbrains-mono-nerd" ]
  [ "$(_get_package_name "fonts-jetbrains-mono-nerd" "apt")" = "" ]
  [ "$(_get_package_name "fonts-jetbrains-mono-nerd" "dnf")" = "" ]

  [ "$(_get_package_name "fonts-liberation" "apt")" = "fonts-liberation" ]
  [ "$(_get_package_name "fonts-liberation" "pacman")" = "ttf-liberation" ]
  [ "$(_get_package_name "fonts-liberation" "dnf")" = "" ]

  [ "$(_get_package_name "fonts-roboto" "apt")" = "fonts-roboto" ]
  [ "$(_get_package_name "fonts-roboto" "dnf")" = "google-roboto-fonts" ]
  [ "$(_get_package_name "fonts-roboto" "pacman")" = "ttf-roboto" ]

  [ "$(_get_package_name "fonts-carlito" "pacman")" = "ttf-carlito" ]
  [ "$(_get_package_name "fonts-carlito" "apt")" = "" ]

  [ "$(_get_package_name "fonts-noto" "pacman")" = "noto-fonts" ]
  [ "$(_get_package_name "fonts-noto" "dnf")" = "" ]

  [ "$(_get_package_name "fonts-noto-color-emoji" "apt")" = "fonts-noto-color-emoji" ]
  [ "$(_get_package_name "fonts-noto-color-emoji" "pacman")" = "noto-fonts-emoji" ]
  [ "$(_get_package_name "fonts-noto-color-emoji" "dnf")" = "" ]
}

@test "_get_package_name resolves docker packages for distros" {
  [ "$(_get_package_name "docker" "apt")" = "docker.io" ]
  [ "$(_get_package_name "docker" "dnf")" = "docker-ce docker-ce-cli" ]
  [ "$(_get_package_name "docker" "pacman")" = "docker" ]

  [ "$(_get_package_name "docker-compose" "apt")" = "docker-compose" ]
  [ "$(_get_package_name "docker-compose" "dnf")" = "docker-compose-plugin" ]
  [ "$(_get_package_name "docker-compose" "pacman")" = "docker-compose" ]

  [ "$(_get_package_name "docker-buildx" "apt")" = "" ]
  [ "$(_get_package_name "docker-buildx" "dnf")" = "docker-buildx-plugin" ]
  [ "$(_get_package_name "docker-buildx" "pacman")" = "docker-buildx" ]

  [ "$(_get_package_name "containerd" "dnf")" = "containerd.io" ]
  [ "$(_get_package_name "containerd" "apt")" = "" ]
  [ "$(_get_package_name "containerd" "pacman")" = "" ]
}
@test "_get_package_name resolves neovim runtime dependencies for distros" {
  [ "$(_get_package_name "clipboard" "apt")" = "xclip" ]
  [ "$(_get_package_name "clipboard" "dnf")" = "xsel" ]
  [ "$(_get_package_name "clipboard" "pacman")" = "wl-clipboard" ]

  [ "$(_get_package_name "fd-find" "apt")" = "fd-find" ]
  [ "$(_get_package_name "fd-find" "dnf")" = "fd-find" ]
  [ "$(_get_package_name "fd-find" "pacman")" = "fd" ]

  [ "$(_get_package_name "imagemagick" "apt")" = "imagemagick" ]
  [ "$(_get_package_name "imagemagick" "dnf")" = "ImageMagick" ]
  [ "$(_get_package_name "imagemagick" "pacman")" = "imagemagick" ]

  [ "$(_get_package_name "protobuf-compiler" "apt")" = "protobuf-compiler" ]
  [ "$(_get_package_name "protobuf-compiler" "dnf")" = "protobuf-compiler" ]
  [ "$(_get_package_name "protobuf-compiler" "pacman")" = "protobuf" ]

  [ "$(_get_package_name "python-venv" "apt")" = "python3-venv" ]
  [ "$(_get_package_name "python-venv" "dnf")" = "" ]
  [ "$(_get_package_name "python-venv" "pacman")" = "" ]

  [ "$(_get_package_name "sqlite" "apt")" = "sqlite3 libsqlite3-dev" ]
  [ "$(_get_package_name "sqlite" "dnf")" = "sqlite sqlite-devel" ]
  [ "$(_get_package_name "sqlite" "pacman")" = "sqlite" ]

  [ "$(_get_package_name "tidy" "apt")" = "tidy" ]
  [ "$(_get_package_name "tidy" "dnf")" = "libtidy" ]
  [ "$(_get_package_name "tidy" "pacman")" = "tidy" ]
}

@test "_get_package_name resolves gaming packages for distros" {
  [ "$(_get_package_name "gamemode" "apt")" = "gamemode" ]
  [ "$(_get_package_name "gamemode" "dnf")" = "gamemode" ]
  [ "$(_get_package_name "gamemode" "pacman")" = "gamemode lib32-gamemode" ]

  [ "$(_get_package_name "mangohud" "apt")" = "" ]
  [ "$(_get_package_name "mangohud" "dnf")" = "mangohud mangohud.i686" ]
  [ "$(_get_package_name "mangohud" "pacman")" = "mangohud lib32-mangohud" ]

  [ "$(_get_package_name "steam" "apt")" = "" ]
  [ "$(_get_package_name "steam" "dnf")" = "steam" ]
  [ "$(_get_package_name "steam" "pacman")" = "steam" ]
}

@test "_get_package_name returns unmapped package as-is" {
  [ "$(_get_package_name "curl" "apt")" = "curl" ]
  [ "$(_get_package_name "curl" "dnf")" = "curl" ]
  [ "$(_get_package_name "curl" "pacman")" = "curl" ]
}

@test "_get_package_manager detects current package manager" {
  run _get_package_manager
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "_get_package_manager returns error when no package manager found" {
  run bash -c "PATH=/empty; source /setup/scripts/_utils.sh; _get_package_manager"
  [ "$status" -eq 1 ]
}

@test "_install_package_from_repository returns error for unsupported manager" {
  run _install_package_from_repository "unknown-pm" "dummy"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "install_packages fails when distribution is unsupported" {
  _get_package_manager() { return 1; }
  run install_packages "curl"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "get_root_filesystem detects root filesystem" {
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "get_shell_profile detects correct profile based on SHELL variable" {
  SHELL=/bin/zsh run get_shell_profile
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.zshrc" ]

  SHELL=/bin/bash run get_shell_profile
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.bashrc" ]

  SHELL=/bin/sh run get_shell_profile
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.profile" ]
}

@test "install_flatpak_app skips when already installed" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo "org.example.App"
      return 0
    fi
    return 1
  }
  run install_flatpak_app "org.example.App" "ExampleApp"
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ installed,\ skipping ]]
}

@test "install_flatpak_app installs app when not present" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo ""
      return 0
    fi
    if [ "$1" = "install" ]; then
      echo "flatpak installed: $*"
      return 0
    fi
    return 1
  }
  sudo() {
    "$@"
  }
  run install_flatpak_app "org.example.App" "ExampleApp"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ExampleApp\ Flatpak\ installed\ successfully ]]
}

@test "download_file downloads successfully via curl or wget" {
  curl() {
    echo "curl downloaded: $*"
    return 0
  }
  run download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
  [ "$status" -eq 0 ]
  [[ "$output" =~ curl\ downloaded ]]
}

@test "fetch_url fetches content successfully via curl or wget" {
  curl() {
    echo "mocked content"
    return 0
  }
  run fetch_url "https://example.com/version.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "mocked content" ]
}

@test "get_desktop_environment detects gnome and plasma correctly" {
  source /setup/scripts/_utils.sh

  XDG_CURRENT_DESKTOP="GNOME" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]

  XDG_CURRENT_DESKTOP="ubuntu:GNOME" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]

  XDG_CURRENT_DESKTOP="KDE" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]

  XDG_CURRENT_DESKTOP="Plasma" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]

  XDG_CURRENT_DESKTOP="X-Cinnamon" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]

  XDG_CURRENT_DESKTOP="" DESKTOP_SESSION="" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}
