# Specification: NVIDIA Graphics Drivers & Hybrid GPU (`scripts/system/setup-nvidia.sh`)

## Purpose
Detects NVIDIA graphics hardware, configures appropriate distribution repositories (including Debian backports for driver and firmware), installs NVIDIA display drivers, sets up Wayland modesetting and power management systemd services, and configures modern hybrid GPU management via **`switcheroo-control`**, **`prime-run`**, and PCIe Runtime D3 (RTD3) dynamic power management for laptops with dual Intel/AMD + NVIDIA graphics across **Debian 13 (Trixie)**, **Fedora 44**, and **Arch Linux**, completely replacing legacy Optimus and archived switching mechanisms.

> [!NOTE]
> **Hardware Testing Status**: This implementation has been thoroughly verified via unit tests and containerized integration test environments across Debian, Fedora, and Arch Linux. Real-world bare-metal hardware validation on physical NVIDIA/hybrid hardware is pending and will be conducted soon to identify any machine-specific adjustments.

---

## Requirements

### Requirement: Hardware Detection & Defensiveness
The script SHALL strictly inspect hardware before attempting any driver installation:
- Inspect PCI devices via `lspci -nn` matching VGA, 3D, or Display controllers with NVIDIA vendor ID (`10de` or string `nvidia`).
- **If NO NVIDIA GPU is present**: The script SHALL output an informative message (`"No NVIDIA GPU detected. Skipping NVIDIA driver setup."`) and exit with status code 0 without modifying repositories or installing packages.
- **Hybrid GPU Detection**: The script SHALL detect whether the system is a hybrid/laptop configuration (presence of an integrated GPU from Intel or AMD alongside the discrete NVIDIA GPU) to configure `switcheroo-control`, `prime-run`, and RTD3 power rules.

### Requirement: Distribution Packaging Strategy & Debian Backports
When an NVIDIA GPU is confirmed, the script SHALL configure native repositories and install packages per distribution:

1. **Debian 13 (Trixie) (`apt`)**:
   - SHALL ensure `contrib`, `non-free`, and `non-free-firmware` are enabled in APT sources.
   - SHALL configure Debian backports repository via `add_debian_backports_repo`.
   - Driver, firmware, and headers SHALL be installed targeting backports (`-t "${codename}-backports"`): `nvidia-driver`, `firmware-misc-nonfree`, `linux-headers-amd64`, `nvidia-smi`, `nvidia-settings`.
   - In case backports installation encounters missing packages for a specific codename, SHALL fallback to standard package installation.

2. **Fedora 44 (`dnf`)**:
   - SHALL ensure the RPM Fusion Nonfree repository is configured via `add_fedora_rpmfusion_repo`.
   - Driver package: `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`.
   - Complementary packages: `xorg-x11-drv-nvidia-power` (for systemd suspend/resume integration).

3. **Arch Linux (`pacman`)**:
   - SHALL ensure multilib repository is active for 32-bit compatibility (`lib32-nvidia-utils`).
   - Driver package: `nvidia-open-dkms` (or `nvidia` for standard linux kernel).
   - Complementary packages: `nvidia-utils`, `nvidia-settings`.

### Requirement: Modern Hybrid GPU Architecture (`switcheroo-control` & `prime-run`)
For laptops with hybrid graphics (Intel/AMD iGPU + NVIDIA dGPU), the script SHALL configure the modern Freedesktop-standard PRIME offload stack:
- SHALL install and enable `switcheroo-control` (`switcheroo-control.service`), enabling native desktop launcher integration in GNOME Shell ("Launch using Discrete Graphic Card") and KDE Plasma.
- SHALL configure the `prime-run` wrapper:
  - On Debian and Arch Linux: install `nvidia-prime` package providing `/usr/bin/prime-run`.
  - On Fedora: install `/usr/local/bin/prime-run` executable script exporting `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only`.
- Legacy Bumblebee, bbswitch, Optimus-Manager, and archived EnvyControl tools SHALL NOT be used.

### Requirement: Power Management, Modesetting & RTD3 Dynamic Power Off
To prevent crashes on Wayland, ensure seamless suspend/resume, and cut dGPU power consumption to 0W when idle:
- SHALL enable `nvidia-suspend.service`, `nvidia-hibernate.service`, and `nvidia-resume.service` if systemd is active.
- SHALL configure `options nvidia-drm modeset=1` in `/etc/modprobe.d/nvidia-modeset.conf`.
- SHALL configure `options nvidia NVreg_PreserveVideoMemoryAllocations=1` in `/etc/modprobe.d/nvidia-power-management.conf`.
- SHALL configure PCIe Runtime D3 (RTD3) dynamic power management:
  - Kernel module option `options nvidia "NVreg_DynamicPowerManagement=0x02"` in `/etc/modprobe.d/nvidia-pm.conf`.
  - Udev rules in `/etc/udev/rules.d/80-nvidia-pm.rules` for automated runtime PM on NVIDIA PCI devices (graphics, audio, and USB controllers).
- On Arch Linux, SHALL verify `nvidia nvidia_modeset nvidia_uvm nvidia_drm` in `/etc/mkinitcpio.conf` if present.

### Requirement: Testing Isolation & Host Safety
To prevent container build failures, host kernel contamination, or kernel panic during automated testing:
- Automated tests (Bats / Docker containers) SHALL NOT compile or insert proprietary kernel modules (`modprobe nvidia`, `akmods`, `dkms`) into the container or host kernel.
- **Repository Availability Validation**: Tests SHALL verify that target driver packages exist and resolve in distribution repositories (e.g., `apt-cache show nvidia-driver`, `dnf repoquery akmod-nvidia`, `pacman -Si nvidia-open-dkms`).
- **Complementary Package Installation**: Tests SHALL validate the installation and configuration of user-space complementary utilities (e.g. `switcheroo-control`).
- The script SHALL support a test/mock override mechanism (`NVIDIA_SKIP_KERNEL_BUILD=1`, `NVIDIA_FORCE_DETECT=1`, `NVIDIA_FORCE_HYBRID=1`) so unit and integration suites run safely and idempotently.

---

## Scenarios

### Scenario: Running on a machine with no NVIDIA GPU
- **GIVEN** a machine with AMD, Intel, or virtual graphics without an NVIDIA GPU
- **WHEN** `scripts/system/setup-nvidia.sh` is executed
- **THEN** it SHALL exit with code 0
- **AND** it SHALL output `"No NVIDIA GPU detected. Skipping NVIDIA driver setup."`
- **AND** it SHALL NOT install driver packages or modify repository sources

### Scenario: Running on Debian 13 with an NVIDIA GPU
- **GIVEN** a Debian 13 system with an NVIDIA GPU detected
- **WHEN** `scripts/system/setup-nvidia.sh` is executed
- **THEN** it SHALL ensure `contrib`, `non-free`, and `non-free-firmware` are enabled
- **AND** it SHALL configure `trixie-backports` repository
- **AND** it SHALL install `nvidia-driver` and `firmware-misc-nonfree` from backports
- **AND** it SHALL configure `nvidia-drm modeset=1` and RTD3 dynamic power management

### Scenario: Running on Fedora 44 with an NVIDIA GPU
- **GIVEN** a Fedora 44 system with an NVIDIA GPU detected
- **WHEN** `scripts/system/setup-nvidia.sh` is executed
- **THEN** it SHALL call `add_fedora_rpmfusion_repo`
- **AND** it SHALL install `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`, and `xorg-x11-drv-nvidia-power`
- **AND** it SHALL configure `nvidia-drm modeset=1` and RTD3 dynamic power management

### Scenario: Running on Arch Linux with an NVIDIA GPU
- **GIVEN** an Arch Linux system with an NVIDIA GPU detected
- **WHEN** `scripts/system/setup-nvidia.sh` is executed
- **THEN** it SHALL ensure `[multilib]` is enabled
- **AND** it SHALL install `nvidia-open-dkms` and `nvidia-utils`
- **AND** it SHALL configure `nvidia-drm modeset=1` and RTD3 dynamic power management

### Scenario: Hybrid GPU detected on a laptop
- **GIVEN** a system with an Intel or AMD primary GPU and an NVIDIA secondary GPU
- **WHEN** `scripts/system/setup-nvidia.sh` is executed
- **THEN** it SHALL install and configure `prime-run`
- **AND** it SHALL install `switcheroo-control`
- **AND** it SHALL enable `switcheroo-control.service`

### Scenario: Running in automated test mode without host hardware
- **GIVEN** a headless testing container or CI environment with `NVIDIA_SKIP_KERNEL_BUILD=1`
- **WHEN** integration tests run
- **THEN** they SHALL validate package existence in the repository without triggering kernel module compilation
- **AND** they SHALL validate installation of complementary user-space packages
