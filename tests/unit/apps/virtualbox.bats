#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-virtualbox.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-virtualbox.sh
}

@test "_install_virtualbox fails when distribution is unsupported" {
  get_distro_id() {
    echo "unsupported_distro"
  }
  run _install_virtualbox
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: unsupported_distro" ]]
}

@test "_install_virtualbox_packages calls add_debian_virtualbox_repo on Debian" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_install_virtualbox_packages calls add_fedora_rpmfusion_repo on Fedora" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  add_fedora_rpmfusion_repo() {
    echo "called add_fedora_rpmfusion_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "fedora"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "called add_fedora_rpmfusion_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_install_virtualbox_packages installs packages on Arch Linux without calling debian repo" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "arch"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_configure_virtualbox_user_group adds user to vboxusers group" {
  export USER="testuser"
  getent() { return 1; }
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _configure_virtualbox_user_group
  [ "$status" -eq 0 ]
  [[ "$output" =~ "User 'testuser' added to vboxusers group." ]]
}

@test "_is_secure_boot_enabled respects force override environment variables" {
  VBOX_FORCE_SECURE_BOOT=1 run _is_secure_boot_enabled
  [ "$status" -eq 0 ]

  VBOX_FORCE_NO_SECURE_BOOT=1 run _is_secure_boot_enabled
  [ "$status" -eq 1 ]
}

@test "_is_secure_boot_enabled detects mokutil SecureBoot enabled status" {
  mokutil() {
    echo "SecureBoot enabled"
    return 0
  }
  run _is_secure_boot_enabled
  [ "$status" -eq 0 ]
}

@test "_install_kernel_headers installs matching headers across distros" {
  sudo() {
    echo "sudo $*"
    return 0
  }
  uname() {
    echo "6.12.0-custom"
  }

  run _install_kernel_headers "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "linux-headers-6.12.0-custom" ]]

  run _install_kernel_headers "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kernel-devel-6.12.0-custom" ]]

  run _install_kernel_headers "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "linux-headers" ]]
}

@test "_configure_virtualbox_secureboot skips when Secure Boot is disabled" {
  _is_secure_boot_enabled() { return 1; }
  run _configure_virtualbox_secureboot
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Secure Boot is disabled or not detected" ]]
}

@test "_configure_virtualbox_secureboot generates MOK keys and dkms config when enabled" {
  _is_secure_boot_enabled() { return 0; }

  local temp_dir
  temp_dir="$(mktemp -d)"
  export MOK_DIR="$temp_dir/mok"
  export MOK_KEY="$MOK_DIR/MOK.priv"
  export MOK_CERT="$MOK_DIR/MOK.der"
  export DKMS_CONF_DIR="$temp_dir/dkms"

  sudo() {
    if [ "$1" = "mkdir" ]; then
      mkdir -p "${@: -1}"
    elif [ "$1" = "openssl" ]; then
      touch "$MOK_KEY" "$MOK_CERT"
    elif [ "$1" = "chmod" ]; then
      chmod 600 "$MOK_KEY"
    elif [ "$1" = "tee" ]; then
      cat > "$2"
    fi
    return 0
  }

  run _configure_virtualbox_secureboot
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Secure Boot detected. Configuring MOK key pair" ]]
  [[ "$output" =~ "MOK key pair generated successfully." ]]
  [ -f "$MOK_KEY" ]
  [ -f "$MOK_CERT" ]
  [ -f "$DKMS_CONF_DIR/vbox-mok.conf" ]

  rm -rf "$temp_dir"
}

@test "_configure_virtualbox_secureboot recognizes already enrolled key" {
  _is_secure_boot_enabled() { return 0; }
  mokutil() { return 0; }

  local temp_dir
  temp_dir="$(mktemp -d)"
  export MOK_DIR="$temp_dir/mok"
  export MOK_KEY="$MOK_DIR/MOK.priv"
  export MOK_CERT="$MOK_DIR/MOK.der"
  export DKMS_CONF_DIR="$temp_dir/dkms"
  mkdir -p "$MOK_DIR" "$DKMS_CONF_DIR"
  touch "$MOK_KEY" "$MOK_CERT"

  sudo() {
    if [ "$1" = "mokutil" ] && [ "$2" = "--test-key" ]; then
      echo "$MOK_CERT is already enrolled"
      return 0
    elif [ "$1" = "tee" ]; then
      cat > "$2"
    elif [ "$1" = "mkdir" ]; then
      mkdir -p "${@: -1}"
    fi
    return 0
  }

  run _configure_virtualbox_secureboot
  [ "$status" -eq 0 ]
  [[ "$output" =~ "MOK certificate is already enrolled in UEFI firmware." ]]

  rm -rf "$temp_dir"
}

@test "_build_virtualbox_modules triggers build commands per distro" {
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _build_virtualbox_modules "debian"
  [ "$status" -eq 0 ]

  akmods() { return 0; }
  run _build_virtualbox_modules "fedora"
  [ "$status" -eq 0 ]

  dkms() { return 0; }
  run _build_virtualbox_modules "arch"
  [ "$status" -eq 0 ]
}

@test "_patch_virtualbox_sources patches source file when unpatched" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  export VBOX_SUPDRV_SRC="$temp_dir/SUPDrv-linux.c"
  echo "#if RTLNX_VER_MIN(6,16,0)" > "$VBOX_SUPDRV_SRC"

  sudo() {
    "$@"
  }

  run _patch_virtualbox_sources
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying kernel compatibility patch to VirtualBox host sources" ]]
  grep -q "^#if 0" "$VBOX_SUPDRV_SRC"

  # Idempotent second run
  run _patch_virtualbox_sources
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Applying kernel compatibility patch" ]]

  rm -rf "$temp_dir"
}

@test "_configure_virtualbox_cfg sets VBOX_BYPASS_MODULES_SIGNATURE_CHECK in vbox.cfg" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  export VBOX_CFG_DIR="$temp_dir"

  sudo() {
    if [ "$1" = "mkdir" ]; then
      mkdir -p "$temp_dir"
    elif [ "$1" = "tee" ]; then
      cat > "$temp_dir/vbox.cfg"
    fi
    return 0
  }

  run _configure_virtualbox_cfg
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring /etc/vbox/vbox.cfg to delegate signature verification to kernel" ]]
  grep -q "^VBOX_BYPASS_MODULES_SIGNATURE_CHECK=1" "$temp_dir/vbox.cfg"

  # Idempotent second run
  run _configure_virtualbox_cfg
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Configuring /etc/vbox/vbox.cfg" ]]

  rm -rf "$temp_dir"
}

@test "_configure_kvm_coexistence configures enable_virt_at_load=0 and unloads active KVM" {
  local temp_dir
  temp_dir="$(mktemp -d)"
  export VBOX_MODPROBE_D_DIR="$temp_dir/modprobe.d"
  export VBOX_KVM_PARAM="$temp_dir/enable_virt_at_load"
  echo "Y" > "$VBOX_KVM_PARAM"

  sudo() {
    if [ "$1" = "mkdir" ]; then
      mkdir -p "$temp_dir/modprobe.d"
    elif [ "$1" = "tee" ]; then
      cat > "$temp_dir/modprobe.d/virtualbox-kvm.conf"
    elif [ "$1" = "modprobe" ]; then
      echo "called modprobe $*"
    fi
    return 0
  }

  run _configure_kvm_coexistence
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring KVM coexistence" ]]
  [[ "$output" =~ "Unloading active KVM modules to release CPU hardware virtualization" ]]
  grep -q "options kvm enable_virt_at_load=0" "$temp_dir/modprobe.d/virtualbox-kvm.conf"

  # Idempotent second run with param = N
  echo "N" > "$VBOX_KVM_PARAM"
  run _configure_kvm_coexistence
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Configuring KVM coexistence" ]]
  [[ ! "$output" =~ "Unloading active KVM modules" ]]

  rm -rf "$temp_dir"
}

@test "_install_virtualbox orchestrates full setup on Debian" {
  get_distro_id() { echo "debian"; }
  _install_kernel_headers() { echo "called _install_kernel_headers"; }
  _install_virtualbox_packages() { echo "called _install_virtualbox_packages"; }
  _patch_virtualbox_sources() { echo "called _patch_virtualbox_sources"; }
  _configure_virtualbox_cfg() { echo "called _configure_virtualbox_cfg"; }
  _configure_kvm_coexistence() { echo "called _configure_kvm_coexistence"; }
  _configure_virtualbox_secureboot() { echo "called _configure_virtualbox_secureboot"; }
  _build_virtualbox_modules() { echo "called _build_virtualbox_modules"; }
  _configure_virtualbox_user_group() { echo "called _configure_virtualbox_user_group"; }

  run _install_virtualbox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_kernel_headers" ]]
  [[ "$output" =~ "called _install_virtualbox_packages" ]]
  [[ "$output" =~ "called _patch_virtualbox_sources" ]]
  [[ "$output" =~ "called _configure_virtualbox_cfg" ]]
  [[ "$output" =~ "called _configure_kvm_coexistence" ]]
  [[ "$output" =~ "called _configure_virtualbox_secureboot" ]]
  [[ "$output" =~ "called _build_virtualbox_modules" ]]
  [[ "$output" =~ "called _configure_virtualbox_user_group" ]]
}

@test "_install_virtualbox orchestrates full setup on Fedora" {
  get_distro_id() { echo "fedora"; }
  _install_kernel_headers() { echo "called _install_kernel_headers"; }
  _install_virtualbox_packages() { echo "called _install_virtualbox_packages"; }
  _patch_virtualbox_sources() { echo "called _patch_virtualbox_sources"; }
  _configure_virtualbox_cfg() { echo "called _configure_virtualbox_cfg"; }
  _configure_kvm_coexistence() { echo "called _configure_kvm_coexistence"; }
  _configure_virtualbox_secureboot() { echo "called _configure_virtualbox_secureboot"; }
  _build_virtualbox_modules() { echo "called _build_virtualbox_modules"; }
  _configure_virtualbox_user_group() { echo "called _configure_virtualbox_user_group"; }

  run _install_virtualbox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_kernel_headers" ]]
  [[ "$output" =~ "called _install_virtualbox_packages" ]]
  [[ "$output" =~ "called _build_virtualbox_modules" ]]
  [[ "$output" =~ "called _configure_virtualbox_user_group" ]]
}

@test "_install_virtualbox orchestrates full setup on Arch Linux" {
  get_distro_id() { echo "arch"; }
  _install_kernel_headers() { echo "called _install_kernel_headers"; }
  _install_virtualbox_packages() { echo "called _install_virtualbox_packages"; }
  _patch_virtualbox_sources() { echo "called _patch_virtualbox_sources"; }
  _configure_virtualbox_cfg() { echo "called _configure_virtualbox_cfg"; }
  _configure_kvm_coexistence() { echo "called _configure_kvm_coexistence"; }
  _configure_virtualbox_secureboot() { echo "called _configure_virtualbox_secureboot"; }
  _build_virtualbox_modules() { echo "called _build_virtualbox_modules"; }
  _configure_virtualbox_user_group() { echo "called _configure_virtualbox_user_group"; }

  run _install_virtualbox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_kernel_headers" ]]
  [[ "$output" =~ "called _install_virtualbox_packages" ]]
  [[ "$output" =~ "called _build_virtualbox_modules" ]]
  [[ "$output" =~ "called _configure_virtualbox_user_group" ]]
}

@test "_install_kernel_headers falls back to generic headers when specific kernel fails" {
  uname() { echo "7.9.9-unknown"; }
  sudo() {
    # Fail specific kernel headers, succeed on generic fallback
    if [[ "$*" =~ "linux-headers-7.9.9-unknown" ]] || [[ "$*" =~ "kernel-devel-7.9.9-unknown" ]]; then
      return 1
    fi
    echo "called sudo $*"
    return 0
  }

  run _install_kernel_headers "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "linux-headers-amd64" ]]

  run _install_kernel_headers "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kernel-devel" ]]
}

@test "_configure_virtualbox_secureboot recognizes key already staged in mokutil list-new" {
  _is_secure_boot_enabled() { return 0; }
  mokutil() { return 0; }

  local temp_dir
  temp_dir="$(mktemp -d)"
  export MOK_DIR="$temp_dir/mok"
  export MOK_KEY="$MOK_DIR/MOK.priv"
  export MOK_CERT="$MOK_DIR/MOK.der"
  export DKMS_CONF_DIR="$temp_dir/dkms"
  mkdir -p "$MOK_DIR" "$DKMS_CONF_DIR"
  touch "$MOK_KEY" "$MOK_CERT"

  sudo() {
    if [ "$1" = "mokutil" ] && [ "$2" = "--test-key" ]; then
      return 1
    elif [ "$1" = "mokutil" ] && [ "$2" = "--list-new" ]; then
      echo "Key 1: VirtualBox Module Signing"
      return 0
    elif [ "$1" = "tee" ]; then
      cat > "$2"
    elif [ "$1" = "mkdir" ]; then
      mkdir -p "${@: -1}"
    fi
    return 0
  }

  run _configure_virtualbox_secureboot
  [ "$status" -eq 0 ]
  [[ "$output" =~ "MOK certificate is already queued for enrollment on next reboot." ]]

  rm -rf "$temp_dir"
}

@test "_configure_virtualbox_secureboot prints non-interactive instructions when VBOX_NONINTERACTIVE=1" {
  _is_secure_boot_enabled() { return 0; }
  mokutil() { return 0; }
  export VBOX_NONINTERACTIVE=1

  local temp_dir
  temp_dir="$(mktemp -d)"
  export MOK_DIR="$temp_dir/mok"
  export MOK_KEY="$MOK_DIR/MOK.priv"
  export MOK_CERT="$MOK_DIR/MOK.der"
  export DKMS_CONF_DIR="$temp_dir/dkms"
  mkdir -p "$MOK_DIR" "$DKMS_CONF_DIR"
  touch "$MOK_KEY" "$MOK_CERT"

  sudo() {
    if [ "$1" = "mokutil" ]; then
      return 1
    elif [ "$1" = "tee" ]; then
      cat > "$2"
    elif [ "$1" = "mkdir" ]; then
      mkdir -p "${@: -1}"
    fi
    return 0
  }

  run _configure_virtualbox_secureboot
  [ "$status" -eq 0 ]
  [[ "$output" =~ "SECURE BOOT ACTION REQUIRED" ]]
  [[ "$output" =~ "sudo mokutil --import" ]]

  rm -rf "$temp_dir"
}
