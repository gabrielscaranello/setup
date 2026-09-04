# Specification: VirtualBox (`scripts/apps/setup-virtualbox.sh`)

## Purpose
Installs Oracle VirtualBox virtualization software and essential host/DKMS modules across supported distributions (specifically targeting **Debian 13 (Trixie)**, **Fedora 44**, and **Arch Linux**), and adds the current user to the `vboxusers` group for USB and device passthrough.

---

## Requirements

### Requirement: Supported Distributions & Target Releases
The installation SHALL strictly target and support:
- **Debian 13 (Trixie)** (`apt`)
- **Fedora 44** (`dnf`)
- **Arch Linux** (`pacman`)

### Requirement: Distribution Packaging Strategy
The script SHALL install VirtualBox using the native packaging mechanism tailored to each target distribution:

1. **Arch Linux (`pacman`)**:
   - SHALL install `virtualbox` and `virtualbox-host-dkms`.
   - Host modules are compiled via DKMS for kernel compatibility.

2. **Debian 13 (`apt`)**:
   - VirtualBox is not in standard Debian main repositories.
   - SHALL configure the official Oracle VirtualBox APT repository via `add_debian_virtualbox_repo` in `scripts/system/debian/_repositories.sh` targeting Debian 13 (`trixie contrib`) with Oracle's official keyring.
   - SHALL install required build and host packages: `dkms` and `virtualbox-7.1`.

3. **Fedora 44 (`dnf`)**:
   - SHALL install VirtualBox via RPM Fusion / DNF (`VirtualBox` and `akmod-VirtualBox`).

### Requirement: Cross-Distro Package Mapping (`scripts/packages.conf`)
The packages SHALL be mapped cleanly in `scripts/packages.conf`:
- `virtualbox`:
  - `apt`: `virtualbox-7.1`
  - `dnf`: `VirtualBox`
  - `pacman`: `virtualbox`
- `virtualbox-host-modules`:
  - `apt`: `dkms`
  - `dnf`: `akmod-VirtualBox`
  - `pacman`: `virtualbox-host-dkms`

### Requirement: User Group Configuration
The script SHALL ensure the current user is added to the `vboxusers` group:
- Checks if `vboxusers` group exists; if not, creates it via `groupadd -f vboxusers`.
- Adds the invoking user (`$SUDO_USER`, `$USER`, or `id -un`) to the `vboxusers` group via `usermod -aG vboxusers`.
- Is idempotent: if the user is already in the group or group creation is skipped, it exits cleanly.

### Scenarios

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system with `pacman`
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL call `install_packages virtualbox virtualbox-host-modules` (installing `virtualbox` and `virtualbox-host-dkms`)
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on Fedora 44
- **GIVEN** a Fedora 44 system with `dnf`
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL call `install_packages virtualbox virtualbox-host-modules` (installing `VirtualBox` and `akmod-VirtualBox`)
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on Debian 13
- **GIVEN** a Debian 13 (Trixie) system with `apt`
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL configure the official Oracle VirtualBox APT repository (`add_debian_virtualbox_repo`) for `trixie`
- **AND** it SHALL call `install_packages virtualbox virtualbox-host-modules` (installing `virtualbox-7.1` and `dkms`)
- **AND** it SHALL ensure the user is added to `vboxusers`

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/apps/setup-virtualbox.sh` is executed
- **THEN** it SHALL exit with code 1 and output an error message to `stderr`
