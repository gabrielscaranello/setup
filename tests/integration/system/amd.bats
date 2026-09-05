#!/usr/bin/env bats

# Integration tests for setup-amd.sh (runs across Debian 13, Fedora 44, and Arch Linux)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
}

@test "setup-amd.sh skips gracefully when no AMD GPU is detected" {
  run bash -c '
    lspci() { echo "00:02.0 VGA compatible controller: Intel Corporation Iris Xe"; }
    export -f lspci
    bash /setup/scripts/system/setup-amd.sh
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No AMD GPU detected. Skipping AMD GPU setup." ]]
  [[ "$output" =~ "setup-amd complete" ]]
}

@test "setup-amd.sh executes cleanly when AMD GPU is detected" {
  export AMD_SKIP_PACKAGE_INSTALL=1
  export AMD_FORCE_DETECT=1
  run bash /setup/scripts/system/setup-amd.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "AMD GPU detected." ]]
  [[ "$output" =~ "setup-amd complete" ]]
}

@test "target AMD packages and firmware exist in distribution repositories" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  case "$pm" in
  apt)
    source /setup/scripts/system/setup-amd.sh
    _configure_repositories "apt"
    apt-cache show firmware-amd-graphics >/dev/null 2>&1 || apt-cache search firmware-amd-graphics | grep -q "firmware-amd-graphics"
    apt-cache show mesa-vulkan-drivers >/dev/null 2>&1 || apt-cache search mesa-vulkan-drivers | grep -q "mesa-vulkan-drivers"
    ;;
  dnf)
    source /setup/scripts/system/fedora/_repositories.sh
    add_fedora_rpmfusion_repo
    dnf repoquery mesa-vulkan-drivers >/dev/null 2>&1 || dnf info mesa-vulkan-drivers >/dev/null 2>&1
    dnf repoquery mesa-va-drivers-freeworld >/dev/null 2>&1 || dnf info mesa-va-drivers-freeworld >/dev/null 2>&1
    ;;
  pacman)
    sudo pacman -Sy --noconfirm 2>/dev/null || true
    pacman -Si vulkan-radeon >/dev/null 2>&1
    pacman -Si mesa >/dev/null 2>&1
    ;;
  esac
}

@test "setup-amd.sh is idempotent (second run succeeds)" {
  export AMD_SKIP_PACKAGE_INSTALL=1
  run bash /setup/scripts/system/setup-amd.sh
  [ "$status" -eq 0 ]
}
