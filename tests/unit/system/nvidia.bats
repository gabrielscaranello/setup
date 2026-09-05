#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-nvidia.sh logic and branching

setup() {
  source /setup/scripts/system/setup-nvidia.sh
}

@test "_setup_nvidia fails when distribution is unsupported" {
  get_distro_id() {
    echo "unsupported_distro"
  }
  run _setup_nvidia
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: unsupported_distro" ]]
}

@test "_setup_nvidia skips and exits 0 when no NVIDIA GPU is detected" {
  get_distro_id() { echo "fedora"; }
  _detect_nvidia_gpu() { return 1; }

  run _setup_nvidia
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No NVIDIA GPU detected. Skipping NVIDIA driver setup." ]]
  [[ ! "$output" =~ "Configuring drivers" ]]
}

@test "_detect_nvidia_gpu detects GPU by vendor id 10de or name" {
  lspci() {
    echo "01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD106M [GeForce RTX 4070 Max-Q] [10de:2860] (rev a1)"
  }
  run _detect_nvidia_gpu
  [ "$status" -eq 0 ]
}

@test "_detect_nvidia_gpu returns 1 when no NVIDIA device is listed" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Raptor Lake-P [Iris Xe Graphics] [8086:a7a0] (rev 04)"
  }
  run _detect_nvidia_gpu
  [ "$status" -eq 1 ]
}

@test "_detect_hybrid_gpu returns true when Intel/AMD iGPU is present alongside dGPU" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Iris Xe Graphics [8086:a7a0]"
    echo "01:00.0 3D controller [0302]: NVIDIA Corporation RTX 4070 [10de:2860]"
  }
  run _detect_hybrid_gpu
  [ "$status" -eq 0 ]
}

@test "_detect_hybrid_gpu returns false on single dedicated NVIDIA GPU system" {
  lspci() {
    echo "01:00.0 VGA compatible controller [0300]: NVIDIA Corporation RTX 4090 [10de:2684]"
  }
  run _detect_hybrid_gpu
  [ "$status" -eq 1 ]
}

@test "_configure_repositories calls add_fedora_rpmfusion_repo on Fedora" {
  add_fedora_rpmfusion_repo() {
    echo "called add_fedora_rpmfusion_repo"
    return 0
  }
  run _configure_repositories "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_rpmfusion_repo" ]]
}

@test "_configure_repositories calls add_arch_multilib_repo on Arch Linux" {
  add_arch_multilib_repo() {
    echo "called add_arch_multilib_repo"
    return 0
  }
  run _configure_repositories "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_arch_multilib_repo" ]]
}

@test "_configure_repositories ensures contrib, non-free and backports on Debian" {
  export APT_DEBIAN_SOURCES="/tmp/test_debian_$$.sources"
  cat << 'EOF' > "$APT_DEBIAN_SOURCES"
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  sudo() { "$@"; }
  apt() { return 0; }
  add_debian_backports_repo() {
    echo "called add_debian_backports_repo"
    return 0
  }

  run _configure_repositories "debian"
  [ "$status" -eq 0 ]
  grep -q "contrib non-free" "$APT_DEBIAN_SOURCES"
  [[ "$output" =~ "called add_debian_backports_repo" ]]
  rm -f "$APT_DEBIAN_SOURCES"
}

@test "_install_driver_packages skips when NVIDIA_SKIP_KERNEL_BUILD is active" {
  export NVIDIA_SKIP_KERNEL_BUILD=1
  run _install_driver_packages "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "NVIDIA_SKIP_KERNEL_BUILD is active. Skipping kernel module compilation step." ]]
}

@test "_install_driver_packages invokes install_packages for target distro" {
  export NVIDIA_SKIP_KERNEL_BUILD=0
  install_packages() {
    echo "installed: $*"
    return 0
  }
  sudo() { "$@"; }
  akmods() { return 0; }
  get_debian_codename() { echo "trixie"; }
  apt() {
    echo "apt called: $*"
    return 0
  }

  run _install_driver_packages "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power" ]]

  run _install_driver_packages "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils" ]]

  run _install_driver_packages "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "apt called: install -y -t trixie-backports nvidia-driver firmware-misc-nonfree linux-headers-amd64 nvidia-smi nvidia-settings" ]]
}

@test "_configure_power_and_modeset configures modprobe, RTD3 rules and systemd services" {
  export MODPROBE_D_DIR="/tmp/test_modprobe_$$.d"
  export UDEV_RULES_DIR="/tmp/test_udev_$$.d"
  export MKINITCPIO_CONF="/tmp/test_mkinitcpio_$$.conf"

  cat << 'EOF' > "$MKINITCPIO_CONF"
MODULES=(btrfs)
EOF
  sudo() { "$@"; }
  systemctl() {
    echo "called systemctl: $*"
    return 0
  }

  run _configure_power_and_modeset
  [ "$status" -eq 0 ]
  [ -f "$MODPROBE_D_DIR/nvidia-modeset.conf" ]
  grep -q "options nvidia-drm modeset=1" "$MODPROBE_D_DIR/nvidia-modeset.conf"
  [ -f "$MODPROBE_D_DIR/nvidia-power-management.conf" ]
  grep -q "options nvidia NVreg_PreserveVideoMemoryAllocations=1" "$MODPROBE_D_DIR/nvidia-power-management.conf"
  [ -f "$MODPROBE_D_DIR/nvidia-pm.conf" ]
  grep -q "NVreg_DynamicPowerManagement=0x02" "$MODPROBE_D_DIR/nvidia-pm.conf"
  [ -f "$UDEV_RULES_DIR/80-nvidia-pm.rules" ]
  grep -q "0x10de" "$UDEV_RULES_DIR/80-nvidia-pm.rules"
  grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" "$MKINITCPIO_CONF"

  rm -rf "$MODPROBE_D_DIR" "$UDEV_RULES_DIR" "$MKINITCPIO_CONF"
}

@test "_configure_power_management_modprobe writes modprobe conf files" {
  export MODPROBE_D_DIR="/tmp/test_modprobe_srp_$$.d"
  sudo() { "$@"; }
  run _configure_power_management_modprobe
  [ "$status" -eq 0 ]
  [ -f "$MODPROBE_D_DIR/nvidia-power-management.conf" ]
  [ -f "$MODPROBE_D_DIR/nvidia-pm.conf" ]
  rm -rf "$MODPROBE_D_DIR"
}

@test "_configure_power_management_udev creates 80-nvidia-pm.rules" {
  export UDEV_RULES_DIR="/tmp/test_udev_srp_$$.d"
  sudo() { "$@"; }
  run _configure_power_management_udev
  [ "$status" -eq 0 ]
  [ -f "$UDEV_RULES_DIR/80-nvidia-pm.rules" ]
  rm -rf "$UDEV_RULES_DIR"
}

@test "_enable_nvidia_systemd_services enables systemd units" {
  sudo() { echo "sudo: $*"; return 0; }
  systemctl() { echo "systemctl: $*"; return 0; }
  run _enable_nvidia_systemd_services
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nvidia-suspend.service" ]]
  [[ "$output" =~ "nvidia-persistenced.service" ]]
}

@test "_setup_hybrid_tools configures switcheroo-control and prime-run" {
  _setup_prime_run() {
    echo "called _setup_prime_run"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  systemctl() {
    echo "called systemctl: $*"
    return 0
  }
  sudo() { "$@"; }

  run _setup_hybrid_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _setup_prime_run" ]]
  [[ "$output" =~ "installed packages: switcheroo-control" ]]
}

@test "_setup_prime_run installs nvidia-prime or creates fallback wrapper script" {
  export PRIME_RUN_PATH="/tmp/test_prime_run_$$"
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "prime-run" ]; then
      return 1
    fi
    builtin command "$@"
  }
  install_packages() { return 1; }
  sudo() { "$@"; }

  run _setup_prime_run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Creating /tmp/test_prime_run_" ]]
  [ -f "$PRIME_RUN_PATH" ]
  grep -q "__NV_PRIME_RENDER_OFFLOAD=1" "$PRIME_RUN_PATH"
  rm -f "$PRIME_RUN_PATH"
}


@test "_configure_drm_modeset writes nvidia-modeset.conf" {
  export MODPROBE_D_DIR="/tmp/test_modeset_$$.d"
  sudo() { "$@"; }

  run _configure_drm_modeset
  [ "$status" -eq 0 ]
  [ -f "$MODPROBE_D_DIR/nvidia-modeset.conf" ]
  grep -q "options nvidia-drm modeset=1" "$MODPROBE_D_DIR/nvidia-modeset.conf"
  rm -rf "$MODPROBE_D_DIR"
}

@test "_configure_power_management writes RTD3 rules and enables services" {
  export MODPROBE_D_DIR="/tmp/test_power_$$.d"
  export UDEV_RULES_DIR="/tmp/test_udev_$$.d"
  sudo() { "$@"; }
  systemctl() {
    echo "systemctl called: $*"
    return 0
  }

  run _configure_power_management
  [ "$status" -eq 0 ]
  [ -f "$MODPROBE_D_DIR/nvidia-power-management.conf" ]
  [ -f "$MODPROBE_D_DIR/nvidia-pm.conf" ]
  [ -f "$UDEV_RULES_DIR/80-nvidia-pm.rules" ]
  [[ "$output" =~ "systemctl called: enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service" ]]
  [[ "$output" =~ "systemctl called: enable nvidia-persistenced.service" ]]

  rm -rf "$MODPROBE_D_DIR" "$UDEV_RULES_DIR"
}

@test "_configure_early_kms updates mkinitcpio.conf when present" {
  export MKINITCPIO_CONF="/tmp/test_early_kms_$$.conf"
  cat << 'EOF' > "$MKINITCPIO_CONF"
MODULES=(btrfs)
EOF
  sudo() { "$@"; }

  run _configure_early_kms
  [ "$status" -eq 0 ]
  grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" "$MKINITCPIO_CONF"
  rm -f "$MKINITCPIO_CONF"
}

@test "setup-nvidia main executes full flow when GPU is present" {
  get_distro_id() { echo "fedora"; }
  _detect_nvidia_gpu() { return 0; }
  _detect_hybrid_gpu() { return 0; }
  _configure_repositories() { return 0; }
  _install_driver_packages() { return 0; }
  _configure_power_and_modeset() { return 0; }
  _setup_hybrid_tools() { echo "hybrid configured"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up NVIDIA graphics drivers..." ]]
  [[ "$output" =~ "Hybrid graphics detected" ]]
  [[ "$output" =~ "setup-nvidia complete" ]]
}
