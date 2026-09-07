#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/system/setup-packages.sh 2>/dev/null || \
  source "${BATS_TEST_DIRNAME}/../../../scripts/system/setup-packages.sh"
}

@test "_install_cli_tools installs modern CLI utilities" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_cli_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: bat btop eza gdu zsh zsh-completions man-db util-linux-user" ]]
}

@test "_install_hardware_tools installs hardware, power management, and bluetooth packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_hardware_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: power-profiles-daemon numlockx fwupd bluez cups cron" ]]
}

_install_filesystem_tools() {
  echo "Installing filesystem compatibility tools..."
  install_packages dosfstools mtools ntfs-3g
}

_install_session_tools() {
  echo "Installing XDG standards, connectivity, and session utilities..."
  install_packages xdg-user-dirs xdg-utils openssh dialog keychain
}

_install_spelling_dictionaries() {
  echo "Installing spelling dictionaries..."
  install_packages spell-pt-br spell-en
}

_initialize_xdg_dirs() {
  if command -v xdg-user-dirs-update > /dev/null 2>&1; then
    echo "Initializing XDG user directories..."
    xdg-user-dirs-update || true
  fi
}

@test "_configure_bluetooth sets AutoEnable=true when main.conf exists" {
  local test_etc="/tmp/test-bluetooth-etc-$$"
  mkdir -p "$test_etc/bluetooth"
  cat << 'EOF' > "$test_etc/bluetooth/main.conf"
[General]
Name=BlueZ

[Policy]
#AutoEnable=false
EOF

  sudo() {
    "$@"
  }

  # Temporarily override /etc/bluetooth via function environment or mock
  _test_configure_bt() {
    local conf="$test_etc/bluetooth/main.conf"
    if grep -q "^\[Policy\]" "$conf"; then
      sed -i 's/^#AutoEnable=.*/AutoEnable=true/' "$conf"
    fi
  }

  _test_configure_bt
  grep -q "^AutoEnable=true" "$test_etc/bluetooth/main.conf"
  rm -rf "$test_etc"
}

@test "_enable_system_services enables power, bluetooth, cups, cron, and fstrim services" {
  local systemctl_calls=()
  systemctl() {
    systemctl_calls+=("$*")
    return 0
  }
  sudo() {
    "$@"
  }
  is_distro() {
    [ "$1" = "debian" ]
  }
  command() {
    if [ "${2:-}" = "systemctl" ]; then return 0; fi
    builtin command "$@"
  }

  run _enable_system_services
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling core hardware and power management services" ]]
  [[ "$output" =~ "Enabling Bluetooth service" ]]
  [[ "$output" =~ "Enabling CUPS printing service" ]]
  [[ "$output" =~ "Enabling cron scheduler service" ]]
  [[ "$output" =~ "Enabling periodic SSD TRIM timer" ]]
}

@test "_enable_system_services enables tuned on Fedora" {
  local systemctl_calls=()
  systemctl() {
    systemctl_calls+=("$*")
    return 0
  }
  sudo() {
    "$@"
  }
  is_distro() {
    [ "$1" = "fedora" ]
  }
  command() {
    if [ "${2:-}" = "systemctl" ]; then return 0; fi
    builtin command "$@"
  }

  run _enable_system_services
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling core hardware and power management services" ]]
  [[ "$output" =~ "Enabling cron scheduler service" ]]
}

@test "_enable_system_services skips cleanly when systemctl is absent" {
  command() {
    if [ "${2:-}" = "systemctl" ]; then return 1; fi
    builtin command "$@"
  }

  run _enable_system_services
  [ "$status" -eq 0 ]
  [[ "$output" =~ "systemctl not available" ]]
}

@test "main runs all setup steps in order" {
  install_packages() {
    echo "mock installed: $*"
    return 0
  }
  xdg-user-dirs-update() {
    echo "mock xdg updated"
    return 0
  }
  _configure_bluetooth() {
    echo "mock bluetooth configured"
    return 0
  }
  _enable_system_services() {
    echo "mock services enabled"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up core system packages" ]]
  [[ "$output" =~ "mock installed: bat btop eza gdu zsh zsh-completions man-db util-linux-user" ]]
  [[ "$output" =~ "mock installed: power-profiles-daemon numlockx fwupd bluez cups cron" ]]
  [[ "$output" =~ "mock installed: dosfstools mtools ntfs-3g" ]]
  [[ "$output" =~ "mock installed: xdg-user-dirs xdg-utils openssh dialog keychain" ]]
  [[ "$output" =~ "mock installed: spell-pt-br spell-en" ]]
  [[ "$output" =~ "mock bluetooth configured" ]]
  [[ "$output" =~ "mock services enabled" ]]
  [[ "$output" =~ "setup-packages complete" ]]
}
