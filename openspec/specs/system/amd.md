# Specification: AMD GPU Driver Stack, Firmware & Codecs (`scripts/system/setup-amd.sh`)

## Purpose

Detects AMD graphics hardware (discrete Radeon GPUs and integrated Ryzen APUs) across **Arch Linux**, **Fedora**, and **Debian 13 (Trixie)**, and configures the required open-source user-space driver stack, non-free firmwares, hardware-accelerated video decoding codecs (VA-API/VDPAU), 32-bit multilib libraries for gaming/Steam, and Vulkan (RADV) runtime support.

---

## Background & Distro Discrepancies

Unlike NVIDIA (which requires out-of-tree kernel modules), the AMD kernel driver (`amdgpu`) is open-source and built into the Linux kernel. However, user-space components, firmware, and video acceleration differ critically across distributions:

1. **Fedora (Patent/Codec Restriction)**:
   - Fedora's base `mesa-va-drivers` and `mesa-vdpau-drivers` packages have H.264, H.265/HEVC, and VC-1 hardware video decoding disabled due to Red Hat legal policy.
   - Without replacing these packages, video playback in browsers and media players forces CPU software decoding, leading to high CPU usage, stuttering, and rapid laptop battery depletion.
   - **Solution**: Swap to `mesa-va-drivers-freeworld` and `mesa-vdpau-drivers-freeworld` from RPM Fusion Free (both 64-bit and 32-bit `.i686`).

2. **Debian 13 (Trixie) (Firmware & Vulkan Granularity)**:
   - Modern AMD GPUs (GCN 3+, RDNA 1/2/3/4) strictly require the proprietary microcode firmware package `firmware-amd-graphics` from `non-free-firmware`.
   - Without this firmware, `amdgpu` fails initialization and the system silently falls back to `llvmpipe` (CPU software rendering).
   - Vulkan is not installed by default; requires `mesa-vulkan-drivers` (and `mesa-vulkan-drivers:i386` for 32-bit).

3. **Arch Linux (Minimal Base & Explicit Userspace)**:
   - Arch Linux provides open-source OpenGL via `mesa`, but Vulkan must be explicitly installed via `vulkan-radeon` (Mesa RADV, recommended over `amdvlk`).
   - 32-bit support requires enabling `[multilib]` and installing `lib32-mesa` and `lib32-vulkan-radeon`.

---

## Requirements

### Requirement: Hardware Detection & Defensiveness

The script SHALL strictly inspect hardware before attempting driver or codec configuration:

- Inspect PCI devices via `lspci -nn` matching VGA, 3D, or Display controllers with AMD/ATI vendor ID (`1002` or string `amd` / `advanced micro devices` / `ati`).
- **If NO AMD GPU is present**: The script SHALL output `"No AMD GPU detected. Skipping AMD GPU setup."` and exit with status code 0.

### Requirement: Distribution Packaging Strategy

1. **Arch Linux (`arch`)**:
   - SHALL ensure the `[multilib]` repository is active in `/etc/pacman.conf`.
   - SHALL install 64-bit packages: `mesa`, `vulkan-radeon`, `libva-utils`, `vulkan-tools`.
   - SHALL install 32-bit packages for gaming: `lib32-mesa`, `lib32-vulkan-radeon`.

2. **Fedora 44 (`fedora`)**:
   - SHALL ensure RPM Fusion Free is configured.
   - SHALL perform package swap from restricted Mesa drivers to freeworld drivers with full codecs:
     - `sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld`
     - `sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld`
   - SHALL install 32-bit freeworld drivers for 32-bit/Steam applications:
     - `sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686` (or install if missing)
     - `sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686`
   - SHALL ensure `mesa-vulkan-drivers`, `vulkan-loader`, `libva-utils`, and `vulkan-tools` are installed.

3. **Debian 13 (Trixie) (`debian`)**:
   - SHALL ensure `non-free-firmware` component is enabled in APT sources.
   - SHALL ensure Debian backports repository is configured.
   - SHALL install `firmware-amd-graphics` and Mesa drivers (`mesa-va-drivers`, `mesa-vdpau-drivers`, `mesa-vulkan-drivers`, `libgl1-mesa-dri`, `libglx-mesa0`, `libegl-mesa0`, `libgbm1`) from backports if available, falling back to main release.
   - SHALL install diagnostic and utility tools: `libvulkan1`, `vainfo`, `vulkan-tools`.
   - On systems with `i386` multiarch enabled: install `mesa-vulkan-drivers:i386`, `libgl1-mesa-dri:i386` (from backports if available).

---

### Requirement: Hardware Acceleration Validation

- The script SHALL provide or verify diagnostic tools:
  - `vainfo` (via `libva-utils` / `vainfo` package) to verify VA-API profiles (H.264, HEVC, AV1).
  - `vulkaninfo` (via `vulkan-tools`) to verify RADV Vulkan instance.
- Optionally install `nvtop` or `radeontop` for terminal-based GPU monitoring.

### Requirement: Testing Isolation & Idempotency

- Running the script a second time SHALL produce no errors or unintended side effects.
- Automated Bats unit and container integration tests SHALL mock hardware detection (`AMD_FORCE_DETECT=1`) and skip destructive swaps when running in test containers without host devices.

---

## Scenarios

### Scenario: Running on a machine with no AMD GPU

- **GIVEN** a machine with only Intel or NVIDIA graphics and no AMD hardware
- **WHEN** `scripts/system/setup-amd.sh` is executed
- **THEN** it SHALL exit with code 0
- **AND** it SHALL output `"No AMD GPU detected. Skipping AMD GPU setup."`

### Scenario: Running on Fedora with AMD GPU

- **GIVEN** a Fedora system with an AMD GPU or APU (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/system/setup-amd.sh` is executed
- **THEN** it SHALL ensure RPM Fusion Free is active
- **AND** it SHALL swap `mesa-va-drivers` to `mesa-va-drivers-freeworld`
- **AND** it SHALL ensure `mesa-vulkan-drivers` is installed

### Scenario: Running on Debian with AMD GPU

- **GIVEN** a Debian 13 system with an AMD GPU or APU (`get_distro_id` returns `debian`)
- **WHEN** `scripts/system/setup-amd.sh` is executed
- **THEN** it SHALL ensure `non-free-firmware` is enabled
- **AND** it SHALL install `firmware-amd-graphics`
- **AND** it SHALL install `mesa-vulkan-drivers` and `mesa-va-drivers`

### Scenario: Running on Arch Linux with AMD GPU

- **GIVEN** an Arch Linux system with an AMD GPU or APU (`get_distro_id` returns `arch`)
- **WHEN** `scripts/system/setup-amd.sh` is executed
- **THEN** it SHALL ensure `[multilib]` is enabled
- **AND** it SHALL install `vulkan-radeon` and `lib32-vulkan-radeon`

### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/system/setup-amd.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
