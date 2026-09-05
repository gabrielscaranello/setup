#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-amd.sh logic and branching

setup() {
  source /setup/scripts/system/setup-amd.sh
}

@test "_setup_amd fails when distribution is unsupported" {
  get_distro_id() {
    echo "unsupported_distro"
  }
  run _setup_amd
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: unsupported_distro" ]]
}

@test "_setup_amd skips and exits 0 when no AMD GPU is detected" {
  get_distro_id() { echo "fedora"; }
  _detect_amd_gpu() { return 1; }

  run _setup_amd
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No AMD GPU detected. Skipping AMD GPU setup." ]]
  [[ ! "$output" =~ "Configuring drivers" ]]
}

@test "_detect_amd_gpu detects GPU by vendor id 1002 or name" {
  lspci() {
    echo "03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 32 [Radeon RX 7700 XT / 7800 XT] [1002:747e] (rev c8)"
  }
  run _detect_amd_gpu
  [ "$status" -eq 0 ]
}

@test "_detect_amd_gpu returns 1 when no AMD device is listed" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Raptor Lake-P [Iris Xe Graphics] [8086:a7a0] (rev 04)"
    echo "01:00.0 3D controller [0302]: NVIDIA Corporation AD106M [GeForce RTX 4070 Max-Q] [10de:2860] (rev a1)"
  }
  run _detect_amd_gpu
  [ "$status" -eq 1 ]
}

@test "_configure_repositories calls appropriate repo helper per distro" {
  add_debian_nonfree_repo() { echo "called nonfree"; }
  add_debian_backports_repo() { echo "called backports"; }
  add_fedora_rpmfusion_repo() { echo "called rpmfusion"; }
  add_arch_multilib_repo() { echo "called multilib"; }

  run _configure_repositories "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called nonfree" ]]
  [[ "$output" =~ "called backports" ]]

  run _configure_repositories "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called rpmfusion" ]]

  run _configure_repositories "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called multilib" ]]
}

@test "_install_arch_amd_packages installs mesa, vulkan-radeon and lib32 packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _install_arch_amd_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: mesa vulkan-radeon libva-utils vulkan-tools" ]]
  [[ "$output" =~ "installed: lib32-mesa lib32-vulkan-radeon" ]]
}

@test "_install_fedora_amd_packages installs mesa-vulkan and performs freeworld swap" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  rpm() { return 1; }
  sudo() { echo "sudo: $*"; return 0; }

  run _install_fedora_amd_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: mesa-vulkan-drivers vulkan-loader libva-utils vulkan-tools" ]]
  [[ "$output" =~ "sudo: dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld" ]]
  [[ "$output" =~ "sudo: dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld" ]]
}

@test "_install_debian_amd_packages installs firmware and mesa vulkan packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  get_debian_codename() { echo "trixie"; }
  sudo() { echo "sudo: $*"; return 0; }
  apt() { echo "apt: $*"; return 0; }

  run _install_debian_amd_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: apt install -y -t trixie-backports firmware-amd-graphics" ]]
  [[ "$output" =~ "mesa-vulkan-drivers" ]]
  [[ "$output" =~ "installed: libvulkan1 vainfo vulkan-tools" ]]
}

@test "_install_arch_32bit_packages installs 32-bit graphics packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _install_arch_32bit_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: lib32-mesa lib32-vulkan-radeon" ]]
}

@test "_swap_fedora_freeworld_drivers swaps restricted drivers for freeworld drivers" {
  rpm() { return 1; }
  sudo() { echo "sudo: $*"; return 0; }

  run _swap_fedora_freeworld_drivers
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld" ]]
  [[ "$output" =~ "sudo: dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld" ]]
}

@test "_install_fedora_32bit_packages installs 32-bit drivers when multilib enabled" {
  export FEDORA_ENABLE_MULTILIB=1
  sudo() { echo "sudo: $*"; return 0; }

  run _install_fedora_32bit_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686" ]]
  [[ "$output" =~ "sudo: dnf install -y mesa-vulkan-drivers.i686" ]]
}

@test "_install_debian_backports_stack installs backports packages with fallback" {
  get_debian_codename() { echo "trixie"; }
  sudo() { echo "sudo: $*"; return 0; }
  install_packages() { echo "fallback: $*"; return 0; }

  run _install_debian_backports_stack
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: apt install -y -t trixie-backports firmware-amd-graphics" ]]
}

@test "_install_debian_32bit_packages installs i386 graphics when multiarch enabled" {
  get_debian_codename() { echo "trixie"; }
  command() { return 0; }
  dpkg() { echo "i386"; return 0; }
  sudo() { echo "sudo: $*"; return 0; }

  run _install_debian_32bit_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: apt install -y -t trixie-backports mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386" ]]
}

@test "_install_amd_packages skips when AMD_SKIP_PACKAGE_INSTALL is active" {
  export AMD_SKIP_PACKAGE_INSTALL=1
  run _install_amd_packages "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "AMD_SKIP_PACKAGE_INSTALL is active. Skipping package installation step." ]]
}

@test "setup-amd main executes full flow when GPU is present" {
  get_distro_id() { echo "fedora"; }
  _detect_amd_gpu() { return 0; }
  _configure_repositories() { return 0; }
  _install_amd_packages() { echo "amd packages installed"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up AMD graphics drivers and codecs..." ]]
  [[ "$output" =~ "AMD GPU detected." ]]
  [[ "$output" =~ "amd packages installed" ]]
  [[ "$output" =~ "setup-amd complete" ]]
}
