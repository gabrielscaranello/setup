# Specification: VirtualBox (`scripts/apps/setup-virtualbox.sh`)

## Purpose

Installs Oracle VirtualBox virtualization software and essential host/DKMS modules across supported distributions (specifically targeting **Debian 13 (Trixie)**, **Fedora 44**, and **Arch Linux**), and adds the current user to the `vboxusers` group for USB and device passthrough.

> [!NOTE]
> **Hardware Testing Status**: This implementation has been thoroughly verified via automated unit and containerized multi-distro integration tests across Debian 13, Fedora 44, and Arch Linux. Real-world bare-metal hardware validation (including UEFI Secure Boot MOK enrollment, kernel header builds, and KVM/AMD-V coexistence) has been successfully verified on **Debian 13**. Physical hardware validation on Fedora and Arch Linux is pending.

---

## Requirements

### Requirement: Supported Distributions & Target Releases

The installation SHALL strictly target and support:

- **Debian 13 (Trixie)** (`debian`)
- **Fedora 44** (`fedora`)
- **Arch Linux** (`arch`)

### Requirement: Distribution Packaging Strategy

The script SHALL install VirtualBox using the native packaging mechanism tailored to each target distribution:

1. **Arch Linux (`arch`)**:
   - SHALL install `virtualbox` and `virtualbox-host-dkms`.
   - Host modules are compiled via DKMS for kernel compatibility.

2. **Debian 13 (`debian`)**:
   - VirtualBox is not in standard Debian main repositories.
   - SHALL configure the official Oracle VirtualBox APT repository via `add_debian_virtualbox_repo` in `scripts/system/debian/_repositories.sh` targeting Debian 13 (`trixie contrib`) with Oracle's official keyring.
   - SHALL install required build and host packages: `dkms` and `virtualbox-7.1`.

3. **Fedora 44 (`fedora`)**:
   - SHALL install VirtualBox via RPM Fusion / DNF (`VirtualBox` and `akmod-VirtualBox`).

### Requirement: Cross-Distro Package Mapping (`scripts/packages.conf`)

The packages SHALL be mapped cleanly in `scripts/packages.conf`:

- `virtualbox`:
  - `debian`: `virtualbox-7.1`
  - `fedora`: `VirtualBox`
  - `arch`: `virtualbox`
- `virtualbox-host-modules`:
  - `debian`: `dkms`
  - `fedora`: `akmod-VirtualBox`
  - `arch`: `virtualbox-host-dkms`

### Requirement: User Group Configuration

The script SHALL ensure the current user is added to the `vboxusers` group:

- Checks if `vboxusers` group exists; if not, creates it via `groupadd -f vboxusers`.
- Adds the invoking user (`$SUDO_USER`, `$USER`, or `id -un`) to the `vboxusers` group via `usermod -aG vboxusers`.
- Is idempotent: if the user is already in the group or group creation is skipped, it exits cleanly.

### Requirement: Kernel Headers Installation

Building and compiling VirtualBox host modules requires the corresponding kernel development headers for the running kernel:

- On **Debian 13**: SHALL attempt to install `linux-headers-$(uname -r)` with fallback to `linux-headers-amd64`.
- On **Fedora 44**: SHALL attempt to install `kernel-devel-$(uname -r)` with fallback to `kernel-devel`.
- On **Arch Linux**: SHALL ensure `linux-headers` is installed.

### Requirement: Kernel Compatibility Patching

On modern kernels (Linux >= 6.16 / 7.x), VirtualBox host sources reference unexported KVM symbols (`kvm_enable_virtualization` / `kvm_disable_virtualization`) in `SUPDrv-linux.c`:

- The script SHALL idempotently patch `/usr/share/virtualbox/src/vboxhost/vboxdrv/linux/SUPDrv-linux.c` if present to avoid compilation failures on kernels without this KVM API.

### Requirement: Secure Boot Support & Module Signing

On systems where UEFI Secure Boot is active:

- The script SHALL detect if Secure Boot is enabled (via `mokutil --sb-state`, EFI variables, or test override flags).
- When Secure Boot is **enabled**:
  - SHALL generate a Machine Owner Key (MOK) pair at `/var/lib/shim-signed/mok/MOK.priv` and `MOK.der` if not already present.
  - SHALL configure DKMS framework to auto-sign modules using the MOK key (`/etc/dkms/framework.conf.d/vbox-mok.conf`).
  - SHALL verify whether the MOK certificate is already enrolled in UEFI via `mokutil --test-key`. If not enrolled, it SHALL notify the user with clear instructions for `mokutil --import` and reboot enrollment.
  - If executed in an interactive terminal session, it MAY prompt to initiate `mokutil --import` automatically.
- When Secure Boot is **disabled**:
  - SHALL skip MOK key generation and enrollment steps.

### Requirement: Kernel Signature Verification Delegation (`/etc/vbox/vbox.cfg`)

On distributions where `extract-module-sig.pl` is not present in kernel development headers, VirtualBox's internal userspace signature verification fails and causes startup loops:

- The script SHALL ensure `VBOX_BYPASS_MODULES_SIGNATURE_CHECK=1` is configured in `/etc/vbox/vbox.cfg` to delegate module signature verification directly to the Linux kernel.

### Requirement: KVM Coexistence & CPU Virtualization Release (`/etc/modprobe.d/virtualbox-kvm.conf`)

On modern Linux kernels, the `kvm` module defaults to acquiring CPU hardware virtualization extensions at module load time (`enable_virt_at_load=Y`), which blocks VirtualBox from acquiring AMD-V (`VERR_SVM_IN_USE`) or Intel VT-x:

- The script SHALL configure `options kvm enable_virt_at_load=0` in `/etc/modprobe.d/virtualbox-kvm.conf` so KVM releases hardware virtualization when idle.
- The script SHALL attempt to unload active KVM modules (`kvm_amd`, `kvm_intel`, `kvm`) if they are currently holding CPU virtualization extensions.

### Requirement: Kernel Module Compilation & Configuration

After packages and keys are set up:

- On **Debian**: SHALL trigger `/sbin/vboxconfig` if present to compile and sign kernel modules.
- On **Fedora**: SHALL trigger `akmods --force` if available.
- On **Arch Linux**: SHALL trigger `dkms autoinstall` if available.

### Scenarios

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL ensure kernel headers (`linux-headers`) are installed
- **AND** it SHALL call `install_packages virtualbox virtualbox-host-modules` (installing `virtualbox` and `virtualbox-host-dkms`)
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on Fedora 44

- **GIVEN** a Fedora 44 system (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL ensure kernel headers (`kernel-devel`) are installed
- **AND** it SHALL call `install_packages virtualbox virtualbox-host-modules` (installing `VirtualBox` and `akmod-VirtualBox`)
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on Debian 13 with Secure Boot enabled

- **GIVEN** a Debian 13 (Trixie) system (`get_distro_id` returns `debian`) with Secure Boot enabled
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL configure the official Oracle VirtualBox APT repository (`add_debian_virtualbox_repo`)
- **AND** it SHALL ensure matching kernel headers (`linux-headers-$(uname -r)`) are installed
- **AND** it SHALL call `install_packages virtualbox virtualbox-host-modules`
- **AND** it SHALL generate MOK keys at `/var/lib/shim-signed/mok/` and configure DKMS signing
- **AND** it SHALL execute `/sbin/vboxconfig` to compile and sign the VirtualBox modules
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on Debian 13 with Secure Boot disabled

- **GIVEN** a Debian 13 (Trixie) system (`get_distro_id` returns `debian`) with Secure Boot disabled
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL skip MOK key generation and enrollment steps
- **AND** it SHALL compile the host modules without signing errors

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL exit with code 1 and output an error message to `stderr`
