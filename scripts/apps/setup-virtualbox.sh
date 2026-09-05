#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
# NOTE: Hardware Testing Status — This script has been verified via automated unit and
# container integration tests across Debian, Fedora, and Arch Linux. Real-world bare-metal
# hardware validation has been performed and verified on Debian 13; physical hardware validation
# on Fedora and Arch Linux is pending real-world testing.
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_configure_virtualbox_user_group() {
  local target_user="${SUDO_USER:-${USER:-$(id -un)}}"
  echo "Configuring vboxusers group for user '$target_user'..."

  if ! getent group vboxusers > /dev/null 2>&1; then
    sudo groupadd -f vboxusers 2> /dev/null || true
  fi

  if [ -n "$target_user" ]; then
    sudo usermod -aG vboxusers "$target_user" 2> /dev/null || true
    echo "User '$target_user' added to vboxusers group."
  fi
}

_is_secure_boot_enabled() {
  if [ "${VBOX_FORCE_SECURE_BOOT:-0}" = "1" ]; then
    return 0
  fi
  if [ "${VBOX_FORCE_NO_SECURE_BOOT:-0}" = "1" ]; then
    return 1
  fi

  if command -v mokutil > /dev/null 2>&1; then
    if mokutil --sb-state 2> /dev/null | grep -iq "SecureBoot enabled"; then
      return 0
    fi
  fi

  if [ -f /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c ] && command -v od > /dev/null 2>&1; then
    local val
    val="$(od -An -t u1 -j 4 -N 1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2> /dev/null | tr -d ' ' || true)"
    if [ "$val" = "1" ]; then
      return 0
    fi
  fi

  return 1
}

_install_kernel_headers() {
  local distro="$1"
  local kver
  kver="$(uname -r 2> /dev/null || true)"

  case "$distro" in
    debian)
      if [ -n "$kver" ]; then
        echo "Ensuring kernel headers for '$kver' are installed on Debian..."
        sudo apt install -y "linux-headers-$kver" 2> /dev/null \
          || sudo apt install -y linux-headers-amd64 2> /dev/null \
          || true
      fi
      ;;
    fedora)
      if [ -n "$kver" ]; then
        echo "Ensuring kernel headers for '$kver' are installed on Fedora..."
        sudo dnf install -y "kernel-devel-$kver" 2> /dev/null \
          || sudo dnf install -y kernel-devel 2> /dev/null \
          || true
      fi
      ;;
    arch)
      echo "Ensuring kernel headers are installed on Arch..."
      sudo pacman -S --needed --noconfirm linux-headers 2> /dev/null || true
      ;;
  esac
}

_configure_virtualbox_secureboot() {
  if ! _is_secure_boot_enabled; then
    echo "Secure Boot is disabled or not detected. Skipping MOK signing configuration."
    return 0
  fi

  echo "Secure Boot detected. Configuring MOK key pair for VirtualBox module signing..."
  local mok_dir="${MOK_DIR:-/var/lib/shim-signed/mok}"
  local mok_priv="${MOK_KEY:-$mok_dir/MOK.priv}"
  local mok_der="${MOK_CERT:-$mok_dir/MOK.der}"

  if [ ! -f "$mok_priv" ] || [ ! -f "$mok_der" ]; then
    echo "Generating MOK key pair in '$mok_dir'..."
    sudo mkdir -m 0700 -p "$mok_dir"
    sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER \
      -addext "extendedKeyUsage=codeSigning" \
      -keyout "$mok_priv" \
      -out "$mok_der" \
      -subj "/CN=VirtualBox Module Signing/" 2> /dev/null || {
      echo "Warning: Failed to generate MOK key pair with openssl." >&2
      return 0
    }
    sudo chmod 600 "$mok_priv"
    echo "MOK key pair generated successfully."
  else
    echo "Existing MOK key pair found in '$mok_dir'."
  fi

  local dkms_conf_dir="${DKMS_CONF_DIR:-/etc/dkms/framework.conf.d}"
  if [ -d "$dkms_conf_dir" ] || [ -d "/etc/dkms" ] || [ -n "${DKMS_CONF_DIR:-}" ]; then
    sudo mkdir -p "$dkms_conf_dir"
    cat << EOF | sudo tee "$dkms_conf_dir/vbox-mok.conf" > /dev/null
mok_signing_key=$mok_priv
mok_certificate=$mok_der
EOF
  fi

  if command -v mokutil > /dev/null 2>&1; then
    if sudo mokutil --test-key "$mok_der" 2>&1 | grep -iq "is already enrolled"; then
      echo "MOK certificate is already enrolled in UEFI firmware."
      return 0
    fi

    if sudo mokutil --list-new 2>&1 | grep -iq "VirtualBox Module Signing"; then
      echo "MOK certificate is already queued for enrollment on next reboot."
      return 0
    fi

    echo "==================================================================="
    echo "  SECURE BOOT ACTION REQUIRED:"
    echo "  MOK signing certificate generated at: $mok_der"
    echo "  To enroll this key in UEFI firmware, run:"
    echo "    sudo mokutil --import $mok_der"
    echo "  Choose a password, then reboot and complete enrollment in MokManager."
    echo "==================================================================="

    if [ -t 0 ] && [ "${VBOX_NONINTERACTIVE:-0}" != "1" ]; then
      echo "Prompting to stage MOK key import now..."
      sudo mokutil --import "$mok_der" || true
      echo "MOK key import staged. Remember your password and enroll at next reboot."
    fi
  fi
}

_configure_virtualbox_cfg() {
  local cfg_dir="${VBOX_CFG_DIR:-/etc/vbox}"
  local cfg_file="$cfg_dir/vbox.cfg"

  sudo mkdir -p "$cfg_dir"
  if [ ! -f "$cfg_file" ] || ! grep -q "^VBOX_BYPASS_MODULES_SIGNATURE_CHECK=" "$cfg_file" 2> /dev/null; then
    echo "Configuring /etc/vbox/vbox.cfg to delegate signature verification to kernel..."
    echo "VBOX_BYPASS_MODULES_SIGNATURE_CHECK=1" | sudo tee -a "$cfg_file" > /dev/null
  fi
}

_configure_kvm_coexistence() {
  local modprobe_d="${VBOX_MODPROBE_D_DIR:-/etc/modprobe.d}"
  local conf_file="$modprobe_d/virtualbox-kvm.conf"

  sudo mkdir -p "$modprobe_d"
  if [ ! -f "$conf_file" ] || ! grep -q "enable_virt_at_load=0" "$conf_file" 2> /dev/null; then
    echo "Configuring KVM coexistence in $conf_file..."
    echo "options kvm enable_virt_at_load=0" | sudo tee "$conf_file" > /dev/null
  fi

  local virt_param="${VBOX_KVM_PARAM:-/sys/module/kvm/parameters/enable_virt_at_load}"
  if [ -f "$virt_param" ] && [ "$(cat "$virt_param" 2> /dev/null)" = "Y" ]; then
    echo "Unloading active KVM modules to release CPU hardware virtualization..."
    sudo modprobe -r kvm_amd kvm_intel kvm 2> /dev/null || true
  fi
}

_build_virtualbox_modules() {
  local distro="$1"
  echo "Setting up and compiling VirtualBox kernel modules..."

  case "$distro" in
    debian)
      if [ -x /sbin/vboxconfig ]; then
        sudo /sbin/vboxconfig 2>&1 || true
      fi
      if command -v modprobe > /dev/null 2>&1; then
        sudo modprobe vboxdrv 2>&1 || true
      fi
      ;;
    fedora)
      if command -v akmods > /dev/null 2>&1; then
        sudo akmods --force 2>&1 || true
      fi
      if command -v modprobe > /dev/null 2>&1; then
        sudo modprobe vboxdrv 2>&1 || true
      fi
      ;;
    arch)
      if command -v dkms > /dev/null 2>&1; then
        sudo dkms autoinstall 2>&1 || true
      fi
      if command -v modprobe > /dev/null 2>&1; then
        sudo modprobe vboxdrv 2>&1 || true
      fi
      ;;
  esac
}

_configure_virtualbox_repositories() {
  local distro="$1"
  if [ "$distro" = "debian" ]; then
    add_debian_virtualbox_repo
  elif [ "$distro" = "fedora" ]; then
    add_fedora_rpmfusion_repo
  fi
}

_install_virtualbox_packages() {
  local distro="${1:-}"
  if [ -n "$distro" ]; then
    _configure_virtualbox_repositories "$distro"
  fi

  echo "Installing VirtualBox packages..."
  install_packages virtualbox virtualbox-host-modules
}

_patch_virtualbox_sources() {
  local supdrv_src="${VBOX_SUPDRV_SRC:-/usr/share/virtualbox/src/vboxhost/vboxdrv/linux/SUPDrv-linux.c}"
  if [ -f "$supdrv_src" ]; then
    if grep -q "^#if RTLNX_VER_MIN(6,16,0)" "$supdrv_src" 2> /dev/null; then
      echo "Applying kernel compatibility patch to VirtualBox host sources..."
      sudo sed -i 's/^#if RTLNX_VER_MIN(6,16,0)/#if 0 \/* RTLNX_VER_MIN(6,16,0) *\//' "$supdrv_src" 2> /dev/null || true
    fi
  fi
}

_install_virtualbox() {
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

  _install_kernel_headers "$distro"
  _install_virtualbox_packages "$distro" || return 1
  _patch_virtualbox_sources
  _configure_virtualbox_cfg
  _configure_kvm_coexistence
  _configure_virtualbox_secureboot
  _build_virtualbox_modules "$distro"
  _configure_virtualbox_user_group
}

main() {
  echo "Setting up VirtualBox..."
  _install_virtualbox
  echo "setup-virtualbox complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
