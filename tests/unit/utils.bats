#!/usr/bin/env bats

# Unit tests for _utils.sh functions and mappings

setup() {
  source /setup/scripts/_utils.sh
}

@test "_get_package_name resolves build-tools for all managers" {
  [ "$(_get_package_name "build-tools" "apt")" = "build-essential" ]
  [ "$(_get_package_name "build-tools" "dnf")" = "@development-tools" ]
  [ "$(_get_package_name "build-tools" "pacman")" = "base-devel" ]
  [ "$(_get_package_name "build-tools" "zypper")" = "patterns-devel-base-devel_basis" ]
  [ "$(_get_package_name "build-tools" "opensuse-leap")" = "patterns-devel-base-devel_basis" ]
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
  [ "$(_get_package_name "clipboard" "apt")" = "wl-clipboard xclip" ]
  [ "$(_get_package_name "clipboard" "dnf")" = "wl-clipboard xsel" ]
  [ "$(_get_package_name "clipboard" "pacman")" = "wl-clipboard" ]
  [ "$(_get_package_name "clipboard" "zypper")" = "wl-clipboard" ]

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

  [ "$(_get_package_name "xhost" "apt")" = "x11-xserver-utils" ]
  [ "$(_get_package_name "xhost" "dnf")" = "xhost" ]
  [ "$(_get_package_name "xhost" "pacman")" = "xorg-xhost" ]
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

@test "_get_package_name resolves desktop environment app packages for distros" {
  [ "$(_get_package_name "kde-gtk-config" "apt")" = "kde-config-gtk-style" ]
  [ "$(_get_package_name "kde-gtk-config" "dnf")" = "kde-gtk-config" ]
  [ "$(_get_package_name "kde-gtk-config" "pacman")" = "kde-gtk-config" ]

  [ "$(_get_package_name "kdeconnect" "apt")" = "kdeconnect" ]
  [ "$(_get_package_name "kdeconnect" "dnf")" = "kde-connect" ]
  [ "$(_get_package_name "kdeconnect" "pacman")" = "kdeconnect" ]

  [ "$(_get_package_name "partitionmanager" "apt")" = "partitionmanager" ]
  [ "$(_get_package_name "partitionmanager" "dnf")" = "kde-partitionmanager" ]
  [ "$(_get_package_name "partitionmanager" "pacman")" = "partitionmanager" ]
}

@test "_get_package_name resolves gnome extension dependencies for distros" {
  [ "$(_get_package_name "gsound" "apt")" = "gir1.2-gsound-1.0" ]
  [ "$(_get_package_name "gsound" "dnf")" = "gsound" ]
  [ "$(_get_package_name "gsound" "pacman")" = "gsound" ]

  [ "$(_get_package_name "libgda" "apt")" = "gir1.2-gda-5.0" ]
  [ "$(_get_package_name "libgda" "dnf")" = "libgda libgda-sqlite" ]
  [ "$(_get_package_name "libgda" "pacman")" = "libgda6" ]
}

@test "_get_package_name resolves nvidia driver package for distros" {
  [ "$(_get_package_name "nvidia-driver" "apt")" = "nvidia-driver" ]
  [ "$(_get_package_name "nvidia-driver" "dnf")" = "akmod-nvidia" ]
  [ "$(_get_package_name "nvidia-driver" "pacman")" = "nvidia-open-dkms nvidia-utils" ]
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

@test "get_repo_root detects repository root directory" {
  run get_repo_root
  [ "$status" -eq 0 ]
  [ -d "$output/scripts" ]
  [ -f "$output/main.sh" ]
}

@test "get_repo_root respects REPO_ROOT_DIR environment override" {
  local mock_root
  mock_root="$(mktemp -d)"
  REPO_ROOT_DIR="$mock_root" run get_repo_root
  [ "$status" -eq 0 ]
  [ "$output" = "$mock_root" ]
  rm -rf "$mock_root"
}

@test "get_root_filesystem detects root filesystem" {
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "write_ini_key creates new file and section when file does not exist" {
  local tmp_file="/tmp/test_write_ini_$$.ini"
  rm -f "$tmp_file"

  run write_ini_key "$tmp_file" "General" "foo" "bar"
  [ "$status" -eq 0 ]
  [ -f "$tmp_file" ]
  grep -q "^\[General\]" "$tmp_file"
  grep -q "^foo=bar" "$tmp_file"

  rm -f "$tmp_file"
}

@test "write_ini_key updates existing key in existing section" {
  local tmp_file="/tmp/test_write_ini_$$.ini"
  cat << 'EOF' > "$tmp_file"
[General]
foo=old_value
bar=baz
EOF

  run write_ini_key "$tmp_file" "General" "foo" "new_value"
  [ "$status" -eq 0 ]
  grep -q "^foo=new_value" "$tmp_file"
  grep -q "^bar=baz" "$tmp_file"
  [ "$(grep -c "^foo=" "$tmp_file")" -eq 1 ]

  rm -f "$tmp_file"
}

@test "write_ini_key replaces commented key in existing section" {
  local tmp_file="/tmp/test_write_ini_$$.ini"
  cat << 'EOF' > "$tmp_file"
[Policy]
#AutoEnable=false
Name=BlueZ
EOF

  run write_ini_key "$tmp_file" "Policy" "AutoEnable" "true"
  [ "$status" -eq 0 ]
  grep -q "^AutoEnable=true" "$tmp_file"
  [ "$(grep -c "AutoEnable" "$tmp_file")" -eq 1 ]

  rm -f "$tmp_file"
}

@test "write_ini_key appends new section without altering existing sections" {
  local tmp_file="/tmp/test_write_ini_$$.ini"
  cat << 'EOF' > "$tmp_file"
[First]
key1=val1
EOF

  run write_ini_key "$tmp_file" "Second" "key2" "val2"
  [ "$status" -eq 0 ]
  grep -q "^\[First\]" "$tmp_file"
  grep -q "^key1=val1" "$tmp_file"
  grep -q "^\[Second\]" "$tmp_file"
  grep -q "^key2=val2" "$tmp_file"

  rm -f "$tmp_file"
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

@test "install_flatpak_app updates when already installed" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo "org.example.App"
      return 0
    fi
    if [ "$1" = "update" ]; then
      echo "flatpak updated: $*"
      return 0
    fi
    return 1
  }
  sudo() { "$@"; }
  run install_flatpak_app "org.example.App" "ExampleApp"
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ installed,\ updating\ to\ latest\ version ]]
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

@test "install_flatpak_app uses fast-path when flatpak and flathub remote exist" {
  flatpak() {
    if [ "$1" = "remotes" ]; then
      echo "flathub"
      return 0
    fi
    if [ "$1" = "list" ]; then
      echo "org.other.App"
      return 0
    fi
    if [ "$1" = "install" ]; then
      echo "fast-path installed: $*"
      return 0
    fi
    return 1
  }
  sudo() { "$@"; }
  run install_flatpak_app "org.example.App" "ExampleApp"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "fast-path installed: install -y --noninteractive flathub org.example.App" ]]
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

  TARGET_DE="gnome" XDG_CURRENT_DESKTOP="KDE" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]

  TARGET_DE="plasma" XDG_CURRENT_DESKTOP="GNOME" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]

  local mock_home="/tmp/mock-home-$$"
  mkdir -p "$mock_home/.config/setup"
  echo "gnome" > "$mock_home/.config/setup/desktop-environment"
  HOME="$mock_home" TARGET_DE="" XDG_CURRENT_DESKTOP="" DESKTOP_SESSION="" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]
  rm -rf "$mock_home"

  TARGET_DE="" XDG_CURRENT_DESKTOP="" DESKTOP_SESSION="" HOME="/nonexistent" run get_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

@test "save_desktop_environment sets TARGET_DE and writes config file" {
  source /setup/scripts/_utils.sh
  local mock_home="/tmp/mock-home-$$"
  HOME="$mock_home" save_desktop_environment "plasma"
  [ "$TARGET_DE" = "plasma" ]
  [ -f "$mock_home/.config/setup/desktop-environment" ]
  [ "$(cat "$mock_home/.config/setup/desktop-environment")" = "plasma" ]
  rm -rf "$mock_home"
}

@test "prompt_desktop_environment returns default when non-interactive" {
  source /setup/scripts/_utils.sh
  run prompt_desktop_environment "Test prompt" "gnome"
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]

  run prompt_desktop_environment "Test prompt"
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]
}

@test "ensure_desktop_environment resolves and saves DE" {
  source /setup/scripts/_utils.sh
  local mock_home="/tmp/mock-home-$$"
  HOME="$mock_home" TARGET_DE="" XDG_CURRENT_DESKTOP="" DESKTOP_SESSION="" run ensure_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]
  [ -f "$mock_home/.config/setup/desktop-environment" ]
  rm -rf "$mock_home"

  HOME="$mock_home" TARGET_DE="gnome" run ensure_desktop_environment
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]
  rm -rf "$mock_home"
}

@test "get_distro_id detects distribution from os-release" {
  local test_os_release="/tmp/test-os-release-$$"
  echo 'ID=debian' > "$test_os_release"

  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "debian" ]

  echo 'ID="Fedora"' > "$test_os_release"
  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "fedora" ]

  echo 'ID=arch' > "$test_os_release"
  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "arch" ]

  echo 'ID=ubuntu' > "$test_os_release"
  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "ubuntu" ]

  echo 'ID="opensuse-leap"' > "$test_os_release"
  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "opensuse-leap" ]

  echo 'ID=opensuse-tumbleweed' > "$test_os_release"
  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "opensuse-tumbleweed" ]

  rm -f "$test_os_release"
}

@test "get_distro_id returns unknown when os-release has no ID" {
  local test_os_release="/tmp/test-empty-os-release-$$"
  echo 'NAME="Linux"' > "$test_os_release"

  OS_RELEASE_PATH="$test_os_release" run get_distro_id
  [ "$status" -eq 1 ]
  [ "$output" = "unknown" ]

  rm -f "$test_os_release"
}


@test "is_distro matches current distribution correctly" {
  get_distro_id() { echo "debian"; }
  run is_distro "debian"
  [ "$status" -eq 0 ]

  run is_distro "arch"
  [ "$status" -eq 1 ]

  get_distro_id() { echo "opensuse-leap"; }
  run is_distro "opensuse"
  [ "$status" -eq 0 ]

  run is_distro "opensuse-leap"
  [ "$status" -eq 0 ]

  run is_distro "fedora"
  [ "$status" -eq 1 ]

  get_distro_id() { echo "opensuse-tumbleweed"; }
  run is_distro "opensuse"
  [ "$status" -eq 0 ]
}

@test "require_supported_distro validates supported distributions" {
  get_distro_id() { echo "debian"; }
  run require_supported_distro
  [ "$status" -eq 0 ]
  [ "$output" = "debian" ]

  get_distro_id() { echo "fedora"; }
  run require_supported_distro
  [ "$status" -eq 0 ]
  [ "$output" = "fedora" ]

  get_distro_id() { echo "arch"; }
  run require_supported_distro
  [ "$status" -eq 0 ]
  [ "$output" = "arch" ]

  get_distro_id() { echo "opensuse-leap"; }
  run require_supported_distro
  [ "$status" -eq 0 ]
  [ "$output" = "opensuse-leap" ]

  get_distro_id() { echo "opensuse-tumbleweed"; }
  run require_supported_distro
  [ "$status" -eq 0 ]
  [ "$output" = "opensuse-tumbleweed" ]

  get_distro_id() { echo "ubuntu"; }
  run require_supported_distro
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: ubuntu" ]]

  get_distro_id() { return 1; }
  run require_supported_distro
  [ "$status" -eq 1 ]
}

@test "_get_package_name resolves packages using distro names" {
  [ "$(_get_package_name "golang" "debian")" = "golang" ]
  [ "$(_get_package_name "golang" "fedora")" = "golang" ]
  [ "$(_get_package_name "golang" "arch")" = "go" ]

  [ "$(_get_package_name "build-tools" "debian")" = "build-essential" ]
  [ "$(_get_package_name "build-tools" "fedora")" = "@development-tools" ]
  [ "$(_get_package_name "build-tools" "arch")" = "base-devel" ]

  [ "$(_get_package_name "nvidia-driver" "debian")" = "nvidia-driver" ]
  [ "$(_get_package_name "nvidia-driver" "fedora")" = "akmod-nvidia" ]
  [ "$(_get_package_name "nvidia-driver" "arch")" = "nvidia-open-dkms nvidia-utils" ]

  [ "$(_get_package_name "power-profiles-daemon" "debian")" = "power-profiles-daemon" ]
  [ "$(_get_package_name "power-profiles-daemon" "fedora")" = "tuned-ppd" ]
  [ "$(_get_package_name "power-profiles-daemon" "arch")" = "power-profiles-daemon" ]

  [ "$(_get_package_name "bluez" "debian")" = "bluez" ]
  [ "$(_get_package_name "bluez" "fedora")" = "bluez" ]
  [ "$(_get_package_name "bluez" "arch")" = "bluez bluez-utils" ]

  [ "$(_get_package_name "cron" "debian")" = "cron" ]
  [ "$(_get_package_name "cron" "fedora")" = "cronie" ]
  [ "$(_get_package_name "cron" "arch")" = "cronie" ]

  [ "$(_get_package_name "extension-manager" "debian")" = "" ]
  [ "$(_get_package_name "extension-manager" "fedora")" = "" ]
  [ "$(_get_package_name "extension-manager" "arch")" = "extension-manager" ]
}

@test "get_gpu_vendor honors GPU_VENDOR environment override" {
  GPU_VENDOR="amd" run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "amd" ]

  GPU_VENDOR="nvidia" run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "nvidia" ]
}

@test "get_gpu_vendor detects nvidia from lspci" {
  lspci() {
    echo "01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD106M [GeForce RTX 4070 Max-Q] [10de:2860] (rev a1)"
  }
  run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "nvidia" ]
}

@test "get_gpu_vendor detects amd from lspci" {
  lspci() {
    echo "03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 32 [Radeon RX 7700 XT] [1002:747e] (rev c8)"
  }
  run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "amd" ]
}

@test "get_gpu_vendor detects intel from lspci" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Raptor Lake-P [Iris Xe Graphics] [8086:a7a0] (rev 04)"
  }
  run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "intel" ]
}

@test "get_gpu_vendor returns unknown when no physical GPU matches" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Red Hat, Inc. Virtio GPU [1af4:1050]"
  }
  run get_gpu_vendor
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

@test "ensure_xdg_terminal_exec deploys xdg-terminal-exec and fallback symlinks" {
  source /setup/scripts/_utils.sh
  local test_home="/tmp/test-utils-terminal-exec-home"
  local mock_sys_bin="/tmp/test-mock-usr-local-bin-utils"
  mkdir -p "$test_home/.local/bin" "$mock_sys_bin"

  HOME="$test_home" run ensure_xdg_terminal_exec
  [ "$status" -eq 0 ]
  [ -x "$test_home/.local/bin/xdg-terminal-exec" ]
  [ -L "$test_home/.local/bin/x-terminal-emulator" ]
  [ -L "$test_home/.local/bin/gnome-terminal" ]
  [ -f "$test_home/.config/environment.d/10-local-path.conf" ]

  rm -rf "$test_home" "$mock_sys_bin"
}

@test "enable_cron_service enables cron.service on debian" {
  source /setup/scripts/_utils.sh
  is_distro() { [ "$1" = "debian" ]; }
  command() { if [ "${2:-}" = "systemctl" ]; then return 0; fi; builtin command "$@"; }
  local systemctl_args=()
  systemctl() { systemctl_args+=("$*"); return 0; }
  sudo() { "$@"; }

  run enable_cron_service
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling cron scheduler service..." ]]
}

@test "enable_cron_service enables crond.service on fedora" {
  source /setup/scripts/_utils.sh
  is_distro() { [ "$1" = "fedora" ]; }
  command() { if [ "${2:-}" = "systemctl" ]; then return 0; fi; builtin command "$@"; }
  local systemctl_args=()
  systemctl() { systemctl_args+=("$*"); return 0; }
  sudo() { "$@"; }

  run enable_cron_service
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling cron scheduler service..." ]]
}

@test "enable_cron_service enables cronie.service on arch" {
  source /setup/scripts/_utils.sh
  is_distro() { [ "$1" = "arch" ]; }
  command() { if [ "${2:-}" = "systemctl" ]; then return 0; fi; builtin command "$@"; }
  local systemctl_args=()
  systemctl() { systemctl_args+=("$*"); return 0; }
  sudo() { "$@"; }

  run enable_cron_service
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling cron scheduler service..." ]]
}

@test "enable_cron_service skips cleanly when systemctl is unavailable" {
  source /setup/scripts/_utils.sh
  command() { if [ "${2:-}" = "systemctl" ]; then return 1; fi; builtin command "$@"; }

  run enable_cron_service
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "enable_cron_service honors an explicit service name" {
  source /setup/scripts/_utils.sh
  command() { if [ "${2:-}" = "systemctl" ]; then return 0; fi; builtin command "$@"; }
  sudo() { echo "sudo $*"; }

  run enable_cron_service "custom-cron"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "enable --now custom-cron.service" ]]
}

@test "write_ini_key preserves backslashes in values" {
  source /setup/scripts/_utils.sh
  local tmp_file
  tmp_file="$(mktemp)"
  write_ini_key "$tmp_file" "General" "path" 'a\nb\tc'
  grep -qF 'path=a\nb\tc' "$tmp_file"
  rm -f "$tmp_file"
}

@test "upgrade_system runs the native upgrade commands for each package manager" {
  source /setup/scripts/_utils.sh
  sudo() { echo "sudo $*"; }

  _get_package_manager() { echo "apt"; }
  run upgrade_system
  [[ "$output" =~ "sudo apt update" ]]
  [[ "$output" =~ "sudo apt upgrade -y" ]]

  _get_package_manager() { echo "dnf"; }
  run upgrade_system
  [[ "$output" =~ "sudo dnf upgrade -y --refresh" ]]

  _get_package_manager() { echo "pacman"; }
  run upgrade_system
  [[ "$output" =~ "sudo pacman -Syu --noconfirm" ]]

  _get_package_manager() { echo "zypper"; }
  get_distro_id() { echo "opensuse-leap"; }
  run upgrade_system
  [[ "$output" =~ "sudo zypper --non-interactive refresh" ]]
  [[ "$output" =~ "sudo zypper --non-interactive up --no-recommends" ]]

  get_distro_id() { echo "opensuse-tumbleweed"; }
  run upgrade_system
  [[ "$output" =~ "sudo zypper --non-interactive dup --no-recommends" ]]
}

@test "upgrade_system fails when no package manager is available" {
  source /setup/scripts/_utils.sh
  _get_package_manager() { return 1; }
  run upgrade_system
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "remove_packages uses native removal commands and optional autoremove" {
  source /setup/scripts/_utils.sh
  sudo() { echo "sudo $*"; }

  _get_package_manager() { echo "apt"; }
  run remove_packages --autoremove foo bar
  [[ "$output" =~ "sudo apt purge -y foo bar" ]]
  [[ "$output" =~ "sudo apt autoremove --purge -y" ]]

  run remove_packages foo
  [[ "$output" =~ "sudo apt purge -y foo" ]]
  [[ ! "$output" =~ "autoremove" ]]

  _get_package_manager() { echo "dnf"; }
  run remove_packages --autoremove foo
  [[ "$output" =~ "sudo dnf remove -y foo" ]]
  [[ "$output" =~ "sudo dnf autoremove -y" ]]

  _get_package_manager() { echo "pacman"; }
  run remove_packages foo
  [[ "$output" =~ "sudo pacman -Rns --noconfirm foo" ]]

  _get_package_manager() { echo "zypper"; }
  run remove_packages foo
  [[ "$output" =~ "sudo zypper --non-interactive remove -u foo" ]]
}

@test "remove_packages is a no-op without packages" {
  source /setup/scripts/_utils.sh
  run remove_packages
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "lock_packages locks on zypper and is no-op on other package managers" {
  source /setup/scripts/_utils.sh
  sudo() { echo "sudo $*"; }

  _get_package_manager() { echo "zypper"; }
  run lock_packages foo
  [[ "$output" =~ "sudo zypper --non-interactive addlock foo" ]]

  _get_package_manager() { echo "apt"; }
  run lock_packages foo
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  _get_package_manager() { echo "dnf"; }
  run lock_packages foo
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  _get_package_manager() { echo "pacman"; }
  run lock_packages foo
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "install_packages_from_repo pins to suite on apt and repo on zypper" {
  source /setup/scripts/_utils.sh
  sudo() { echo "sudo $*"; }

  run install_packages_from_repo "trixie-backports" linux-image-amd64
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo apt install -y -t trixie-backports linux-image-amd64" ]]

  run install_packages_from_repo "Kernel:stable" kernel-default
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo zypper --non-interactive install -y --from Kernel:stable kernel-default" ]]

  _get_package_manager() { echo "pacman"; }
  run install_packages_from_repo "custom-repo" foo
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager for repository pinning" ]]
}

@test "swap_packages dispatches to package manager swap adapters" {
  source /setup/scripts/_utils.sh
  sudo() { echo "sudo $*"; }

  _get_package_manager() { echo "dnf"; }
  run swap_packages mesa-va-drivers mesa-va-drivers-freeworld
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld" ]]

  run swap_packages --allowerasing ffmpeg-free ffmpeg
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing" ]]

  _get_package_manager() { echo "apt"; }
  run swap_packages libavcodec58 libavcodec-extra58
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo apt install -y libavcodec-extra58" ]]

  _get_package_manager() { echo "zypper"; }
  run swap_packages ffmpeg-4 ffmpeg-6
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo zypper --non-interactive install -y --allow-vendor-change ffmpeg-6" ]]

  _get_package_manager() { echo "pacman"; }
  run swap_packages pkg-a pkg-b
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo pacman -S --needed --noconfirm pkg-b" ]]
}

@test "_get_package_name resolves python3 and python-pip for all managers and distros" {
  [ "$(_get_package_name "python3" "debian")" = "python3" ]
  [ "$(_get_package_name "python3" "fedora")" = "python3" ]
  [ "$(_get_package_name "python3" "arch")" = "python" ]
  [ "$(_get_package_name "python3" "opensuse-tumbleweed")" = "python3" ]

  [ "$(_get_package_name "python-pip" "debian")" = "python3-pip" ]
  [ "$(_get_package_name "python-pip" "fedora")" = "python3-pip" ]
  [ "$(_get_package_name "python-pip" "arch")" = "python-pip" ]
  [ "$(_get_package_name "python-pip" "opensuse-tumbleweed")" = "python3-pip" ]
}

@test "is_wsl detects WSL environment via WSL_DISTRO_NAME, WSLInterop, or /proc/version" {
  source /setup/scripts/_utils.sh
  local fake_proc="/tmp/test-proc-version-$$"
  local fake_interop="/tmp/test-wsl-interop-$$"
  rm -f "$fake_proc" "$fake_interop"

  echo "Linux version 6.8.0-generic (gcc)" > "$fake_proc"
  WSL_DISTRO_NAME="" WSL_INTEROP_PATH="$fake_interop" PROC_VERSION_PATH="$fake_proc" run is_wsl
  [ "$status" -eq 1 ]

  WSL_DISTRO_NAME="Debian" WSL_INTEROP_PATH="$fake_interop" PROC_VERSION_PATH="$fake_proc" run is_wsl
  [ "$status" -eq 0 ]

  touch "$fake_interop"
  WSL_DISTRO_NAME="" WSL_INTEROP_PATH="$fake_interop" PROC_VERSION_PATH="$fake_proc" run is_wsl
  [ "$status" -eq 0 ]
  rm -f "$fake_interop"

  echo "Linux version 5.15.153.1-microsoft-standard-WSL2" > "$fake_proc"
  WSL_DISTRO_NAME="" WSL_INTEROP_PATH="$fake_interop" PROC_VERSION_PATH="$fake_proc" run is_wsl
  [ "$status" -eq 0 ]

  rm -f "$fake_proc"
}
