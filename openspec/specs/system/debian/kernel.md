# Specification: Debian Backports Kernel (`scripts/system/debian/setup-kernel.sh`)

## Purpose
Installs the latest modern Linux kernel and headers from Debian Backports on Debian installations, bypassing execution on non-Debian systems.

---

## Requirements

### Requirement: Distribution Guard
The script SHALL check the target distribution using `get_distro_id` and exit cleanly with code 0 if run on non-Debian distributions (`fedora` or `arch`).

### Requirement: Backports Kernel Installation
The script SHALL ensure backports repository is configured via `add_debian_backports_repo` and install `linux-image-amd64` and `linux-headers-amd64` targeted to `${codename}-backports`.

#### Scenario: Execution on Debian
- **GIVEN** a Debian installation (`get_distro_id` returns `debian`)
- **WHEN** `scripts/system/debian/setup-kernel.sh` is executed
- **THEN** `sudo apt install -y -t "<codename>-backports" linux-image-amd64 linux-headers-amd64` SHALL be executed

#### Scenario: Execution on Fedora or Arch
- **GIVEN** a Fedora or Arch Linux system (`get_distro_id` returns `fedora` or `arch`)
- **WHEN** `scripts/system/debian/setup-kernel.sh` is executed
- **THEN** it SHALL output a skip notice and exit with status 0
