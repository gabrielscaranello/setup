#!/usr/bin/env bats

# Integration tests for setup-nvidia.sh (runs across Debian 13, Fedora 44, and Arch Linux)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
}

@test "setup-nvidia.sh exits 0 cleanly when no NVIDIA GPU is detected in container" {
  run bash /setup/scripts/system/setup-nvidia.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No NVIDIA GPU detected. Skipping NVIDIA driver setup." ]]
  [[ "$output" =~ "setup-nvidia complete" ]]
}

@test "target NVIDIA driver packages are available in distribution repositories" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  case "$pm" in
  apt)
    # In Debian, ensure contrib/non-free is present then check package availability
    source /setup/scripts/system/setup-nvidia.sh
    _configure_repositories "apt"
    apt-cache show nvidia-driver >/dev/null 2>&1 || apt-cache search nvidia-driver | grep -q "nvidia-driver"
    apt-cache show firmware-misc-nonfree >/dev/null 2>&1 || apt-cache search firmware-misc-nonfree | grep -q "firmware-misc-nonfree"
    ;;
  dnf)
    # In Fedora, configure RPM Fusion repository then verify akmod-nvidia
    source /setup/scripts/system/fedora/_repositories.sh
    add_fedora_rpmfusion_repo
    dnf repoquery akmod-nvidia >/dev/null 2>&1 || dnf info akmod-nvidia >/dev/null 2>&1
    ;;
  pacman)
    # In Arch Linux, check nvidia-open-dkms or nvidia-utils in extra repository
    sudo pacman -Sy --noconfirm 2>/dev/null || true
    pacman -Si nvidia-open-dkms >/dev/null 2>&1 || pacman -Si nvidia-utils >/dev/null 2>&1
    ;;
  esac
}

@test "complementary hybrid graphics tool switcheroo-control installs cleanly" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  install_packages switcheroo-control

  case "$pm" in
  apt) dpkg -l switcheroo-control ;;
  dnf) rpm -q switcheroo-control ;;
  pacman) pacman -Q switcheroo-control ;;
  esac
}

@test "prime-run wrapper or utility installs and executes commands successfully" {
  source /setup/scripts/system/setup-nvidia.sh
  _setup_prime_run
  command -v prime-run >/dev/null 2>&1
  run prime-run echo "prime test ok"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "prime test ok" ]]
}

@test "setup-nvidia.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/system/setup-nvidia.sh
  [ "$status" -eq 0 ]
}
