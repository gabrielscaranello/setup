#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
# NOTE: Hardware Testing Status — This script has been verified via automated unit and
# container integration tests. Bare-metal validation on physical NVIDIA/hybrid hardware
# is pending and will be performed to verify real-world edge cases.
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true

_detect_nvidia_gpu() {
  if [ "${NVIDIA_FORCE_DETECT:-0}" = "1" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' | grep -iq "10de" \
    || lspci 2> /dev/null | grep -iE 'vga|3d|display' | grep -iq "nvidia"
}

_detect_hybrid_gpu() {
  if [ "${NVIDIA_FORCE_HYBRID:-0}" = "1" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  # Detect presence of secondary integrated GPU (Intel or AMD) alongside the NVIDIA dGPU
  local other_gpus
  other_gpus="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' | grep -iv "10de" | grep -iE 'intel|amd|advanced micro devices' || true)"
  [ -n "$other_gpus" ]
}

_configure_repositories() {
  local distro="$1"

  case "$distro" in
    debian)
      add_debian_nonfree_repo
      add_debian_backports_repo
      ;;
    fedora)
      add_fedora_rpmfusion_repo
      ;;
    arch)
      add_arch_multilib_repo
      ;;
  esac
}

_install_debian_driver() {
  local codename
  codename="$(get_debian_codename)"
  echo "Installing kernel headers, firmware, and NVIDIA driver on Debian from backports (${codename}-backports)..."
  sudo apt install -y -t "${codename}-backports" nvidia-driver firmware-misc-nonfree linux-headers-amd64 nvidia-smi nvidia-settings 2> /dev/null \
    || sudo apt install -y -t "${codename}-backports" nvidia-driver firmware-misc-nonfree linux-headers-amd64 2> /dev/null \
    || install_packages linux-headers-amd64 firmware-misc-nonfree nvidia-driver nvidia-smi nvidia-settings
}

_install_fedora_driver() {
  echo "Installing NVIDIA driver via RPM Fusion on Fedora..."
  install_packages akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power
  echo "Triggering Akmods kernel module build..."
  sudo akmods --force 2> /dev/null || true
}

_install_arch_driver() {
  echo "Installing NVIDIA driver and utilities on Arch Linux..."
  install_packages nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils
}

_install_driver_packages() {
  local distro="$1"

  if [ "${NVIDIA_SKIP_KERNEL_BUILD:-0}" = "1" ]; then
    echo "NVIDIA_SKIP_KERNEL_BUILD is active. Skipping kernel module compilation step."
    return 0
  fi

  case "$distro" in
    debian) _install_debian_driver ;;
    fedora) _install_fedora_driver ;;
    arch) _install_arch_driver ;;
  esac
}

_configure_drm_modeset() {
  local modprobe_dir="${MODPROBE_D_DIR:-/etc/modprobe.d}"
  sudo mkdir -p "$modprobe_dir"
  echo "Configuring Wayland DRM modesetting..."
  echo "options nvidia-drm modeset=1" | sudo tee "$modprobe_dir/nvidia-modeset.conf" > /dev/null
}

_configure_power_management_modprobe() {
  local modprobe_dir="${MODPROBE_D_DIR:-/etc/modprobe.d}"
  sudo mkdir -p "$modprobe_dir"

  echo "Configuring NVIDIA power management modprobe options..."
  echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee "$modprobe_dir/nvidia-power-management.conf" > /dev/null
  echo 'options nvidia "NVreg_DynamicPowerManagement=0x02"' | sudo tee "$modprobe_dir/nvidia-pm.conf" > /dev/null
}

_configure_power_management_udev() {
  local udev_dir="${UDEV_RULES_DIR:-/etc/udev/rules.d}"
  sudo mkdir -p "$udev_dir"

  echo "Configuring NVIDIA PCIe RTD3 dynamic power management udev rules..."
  cat << 'EOF' | sudo tee "$udev_dir/80-nvidia-pm.rules" > /dev/null
# Enable runtime PM for NVIDIA VGA/3D controller devices on Driver binds
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="0"
# Enable runtime PM for NVIDIA Audio devices on Driver binds
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="0"
# Enable runtime PM for NVIDIA USB xHCI Host Controller devices on Driver binds
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="0"
# Enable runtime PM for NVIDIA USB Type-C UCSI devices on Driver binds
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="0"
EOF
}

_enable_nvidia_systemd_services() {
  if command -v systemctl > /dev/null 2>&1; then
    echo "Enabling NVIDIA power management and persistence services..."
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2> /dev/null || true
    sudo systemctl enable nvidia-persistenced.service 2> /dev/null || true
  fi
}

_configure_power_management() {
  _configure_power_management_modprobe
  _configure_power_management_udev
  _enable_nvidia_systemd_services
}

_configure_early_kms() {
  local mkinitcpio_file="${MKINITCPIO_CONF:-/etc/mkinitcpio.conf}"

  if [ -f "$mkinitcpio_file" ]; then
    echo "Configuring early KMS in mkinitcpio..."
    if ! grep -Eq "MODULES=\(.*nvidia.*" "$mkinitcpio_file" 2> /dev/null; then
      sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinitcpio_file" 2> /dev/null || true
      sudo sed -i 's/  */ /g' "$mkinitcpio_file" 2> /dev/null || true
    fi
  fi
}

_configure_power_and_modeset() {
  _configure_drm_modeset
  _configure_power_management
  _configure_early_kms
}

_setup_prime_run() {
  local prime_bin="${PRIME_RUN_PATH:-/usr/local/bin/prime-run}"

  if command -v prime-run > /dev/null 2>&1 || [ -f "$prime_bin" ]; then
    return 0
  fi

  echo "Setting up prime-run utility..."
  install_packages nvidia-prime 2> /dev/null || true

  if ! command -v prime-run > /dev/null 2>&1 && [ ! -f "$prime_bin" ]; then
    echo "Creating $prime_bin wrapper for PRIME render offload..."
    cat << 'EOF' | sudo tee "$prime_bin" > /dev/null
#!/bin/sh
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only exec "$@"
EOF
    sudo chmod +x "$prime_bin"
  fi
}

_enable_switcheroo_control() {
  echo "Installing and enabling switcheroo-control service..."
  install_packages switcheroo-control 2> /dev/null || true

  if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl enable --now switcheroo-control 2> /dev/null || sudo systemctl enable switcheroo-control 2> /dev/null || true
  fi
}

_setup_hybrid_tools() {
  echo "Setting up hybrid GPU management tools (switcheroo-control & prime-run)..."
  _setup_prime_run
  _enable_switcheroo_control
}

_setup_nvidia() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch) ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac

  if ! _detect_nvidia_gpu; then
    echo "No NVIDIA GPU detected. Skipping NVIDIA driver setup."
    return 0
  fi

  echo "NVIDIA GPU detected. Configuring drivers for '$distro'..."
  _configure_repositories "$distro"
  _install_driver_packages "$distro"
  _configure_power_and_modeset

  if _detect_hybrid_gpu; then
    echo "Hybrid graphics detected (laptop configuration)."
    _setup_hybrid_tools
  else
    echo "Dedicated single-GPU configuration detected."
  fi
}

main() {
  echo "Setting up NVIDIA graphics drivers..."
  _setup_nvidia
  echo "setup-nvidia complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
