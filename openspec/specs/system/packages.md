# Specification: Core System Packages Provisioning (`scripts/system/setup-packages.sh`)

## Purpose

Provisions foundational operating system packages, modern command-line productivity tools, hardware and power management daemons, multi-filesystem drivers, XDG directory standards, and language dictionaries across supported distributions (**Debian 13**, **Fedora 44**, and **Arch Linux**). This module is strictly decoupled from any Desktop Environment (GNOME or KDE Plasma).

---

## Requirements

### Requirement: Modern CLI & Productivity Tools Installation

The script SHALL install modern command-line utilities and shell environments across supported distributions using `install_packages`:

- `bat`: Cat clone with syntax highlighting and Git integration.
- `btop`: Modern terminal resource and process monitor.
- `eza`: Modern replacement for `ls` with tree view and metadata formatting.
- `gdu`: Fast console disk usage analyzer.
- `zsh` & `zsh-completions`: Z shell and extended autocompletions.
- `man-db`: System documentation and manual reader (`man`).
- `util-linux-user` (Fedora): Provides `chsh` on Fedora <= 43 (graceful resolution on Fedora >= 44 where merged into `util-linux`).

#### Scenario: Installing CLI productivity tools on Debian

- **GIVEN** Debian 13 (Trixie)
- **WHEN** `scripts/system/setup-packages.sh` executes
- **THEN** `bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, and `man-db` SHALL be installed via `install_packages`

#### Scenario: Installing CLI productivity tools on Fedora

- **GIVEN** Fedora 44
- **WHEN** `scripts/system/setup-packages.sh` executes
- **THEN** `bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, and `util-linux-user` SHALL be installed via `install_packages`

#### Scenario: Installing CLI productivity tools on Arch Linux

- **GIVEN** Arch Linux
- **WHEN** `scripts/system/setup-packages.sh` executes
- **THEN** `bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, and `man-db` SHALL be installed via `install_packages`

---

### Requirement: Hardware, Energy, Firmware, Printing & Bluetooth Daemons Installation

The script SHALL install hardware management, power profiling, firmware update, printing, cron scheduling, and Bluetooth stack packages via `install_packages`:

- `power-profiles-daemon`: DBus-based power profile manager (`power-profiles-daemon` on Debian/Arch, `tuned-ppd` on Fedora 41+).
- `numlockx`: Utility to enable NumLock on keyboard during session initialization.
- `fwupd`: Linux Vendor Firmware Service (LVFS) client (including `fwupd-efi` on Arch Linux).
- `bluez`: Official Linux Bluetooth protocol stack and tools (`bluez` on Debian/Fedora, `bluez` and `bluez-utils` on Arch Linux).
- `cups`: OpenPrinting CUPS daemon and printing system.
- `cron`: Job scheduler daemon (`cron` on Debian, `cronie` on Fedora and Arch Linux).

#### Scenario: Installing hardware and power utilities across distros

- **GIVEN** a supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** hardware package installation executes
- **THEN** `power-profiles-daemon` (resolving to `tuned-ppd` on Fedora), `numlockx`, `fwupd` (plus `fwupd-efi` on Arch Linux), `bluez` (plus `bluez-utils` on Arch Linux), `cups`, and `cron` (resolving to `cronie` on Fedora and Arch Linux) SHALL be installed via `install_packages`

---

### Requirement: Bluetooth Policy Configuration

The script SHALL ensure that the Bluetooth controller is configured to power on automatically via `_configure_bluetooth`:

- SHALL verify if `/etc/bluetooth/main.conf` or `/etc/bluetooth` exists.
- SHALL configure `AutoEnable=true` under `[Policy]` section idempotently.

#### Scenario: Configuring Bluetooth auto-enable

- **GIVEN** `/etc/bluetooth/main.conf` exists
- **WHEN** `_configure_bluetooth` executes
- **THEN** `[Policy]` section SHALL contain `AutoEnable=true`

---

### Requirement: Essential System Services Enablement

The script SHALL enable systemd services and timers via `_enable_system_services` when `systemctl` is present:

- Power management: `tuned.service` on Fedora; `power-profiles-daemon.service` on Debian and Arch Linux.
- Bluetooth stack: `bluetooth.service` across all distributions.
- Printing subsystem: `cups.service` across all distributions.
- Cron scheduler: `cron.service` on Debian; `cronie.service` on Fedora and Arch Linux.
- Storage maintenance: `fstrim.timer` for periodic SSD TRIM across all distributions.
- When `systemctl` is not available, service enablement steps SHALL be bypassed cleanly.

#### Scenario: Enabling services on systemd environment

- **GIVEN** system running systemd
- **WHEN** `_enable_system_services` executes
- **THEN** power management service, `bluetooth.service`, `cups.service`, cron service, and `fstrim.timer` SHALL be enabled

---

### Requirement: Filesystem Compatibility Tools Installation

The script SHALL install filesystem drivers and manipulation utilities to ensure out-of-the-box compatibility with external media and non-Linux partitions:

- `dosfstools`: FAT16/FAT32 creation and verification utilities (`mkfs.vfat`, `fsck.vfat`).
- `mtools`: Utilities to access MS-DOS disks without mounting.
- `ntfs-3g`: Read/write driver for NTFS filesystems.

#### Scenario: Installing filesystem tools

- **GIVEN** a supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** filesystem package installation executes
- **THEN** `dosfstools`, `mtools`, and `ntfs-3g` SHALL be installed via `install_packages`

---

### Requirement: XDG Standards, Connectivity & Session Utilities

The script SHALL install standard desktop integration utilities, SSH connectivity clients, and terminal dialog utilities:

- `xdg-user-dirs`: Tool to create and manage localized user directories (`~/Downloads`, `~/Documents`, etc.).
- `xdg-utils`: Command-line tools for desktop integration tasks (`xdg-open`, `xdg-mime`, etc.).
- `openssh`: SSH client utilities (`openssh-client` on Debian, `openssh-clients` on Fedora, `openssh` on Arch Linux).
- `dialog`: Utility for displaying friendly dialog boxes from shell scripts.
- `keychain`: SSH agent and GPG agent manager for shells.

#### Scenario: Installing XDG and connectivity utilities

- **GIVEN** a supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** connectivity package installation executes
- **THEN** `xdg-user-dirs`, `xdg-utils`, `openssh`, `dialog`, and `keychain` SHALL be installed via `install_packages`

---

### Requirement: Spelling Dictionaries Installation

The script SHALL install spell checking dictionaries for Brazilian Portuguese and English via generic package mappings:

- `spell-pt-br`: Brazilian Portuguese dictionary (`hunspell-pt-br` on Debian, `hunspell-pt-BR` on Fedora, `aspell-pt` on Arch Linux).
- `spell-en`: US English dictionary (`hunspell-en-us` on Debian, `hunspell-en-US` on Fedora, `aspell-en` on Arch Linux).

#### Scenario: Installing spell checking dictionaries

- **GIVEN** a supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** dictionary installation executes
- **THEN** Portuguese and English spell checking packages SHALL be resolved via `packages.conf` and installed via `install_packages`

---

### Requirement: XDG User Directories Initialization

After installing `xdg-user-dirs`, the script SHALL initialize the default user directories by running `xdg-user-dirs-update` if the command is available.

#### Scenario: Initializing user directories

- **GIVEN** `xdg-user-dirs-update` binary exists in PATH
- **WHEN** `scripts/system/setup-packages.sh` completes package installation
- **THEN** `xdg-user-dirs-update` SHALL be executed to generate standard user folders

---

### Requirement: Cross-Distribution Package Mapping Contract (`packages.conf`)

Package differences across distributions SHALL be declared in `scripts/packages.conf` in alphabetical order, following the column-aligned format `GENERIC_NAME | DEBIAN | FEDORA | ARCH`:

- `fwupd`: `fwupd | fwupd | fwupd | fwupd fwupd-efi`
- `openssh`: `openssh | openssh-client | openssh-clients | openssh`
- `spell-en`: `spell-en | hunspell-en-us | hunspell-en-US | aspell-en`
- `spell-pt-br`: `spell-pt-br | hunspell-pt-br | hunspell-pt-BR | aspell-pt`
- `util-linux-user`: `util-linux-user | - | util-linux-user | -`
- `zsh-completions`: `zsh-completions | - | - | zsh-completions`

Packages with identical names (`bat`, `btop`, `dialog`, `dosfstools`, `eza`, `gdu`, `keychain`, `man-db`, `mtools`, `ntfs-3g`, `numlockx`, `power-profiles-daemon`, `xdg-user-dirs`, `xdg-utils`, `zsh`) SHALL NOT be added to `packages.conf` and SHALL resolve automatically via fallback.

#### Scenario: Resolving mapped packages

- **GIVEN** `scripts/packages.conf` contains the declared mappings
- **WHEN** `install_packages` is called with mapped generic names
- **THEN** package managers SHALL receive the correct distro-specific package names

---

### Requirement: Idempotency and Script Structure Contract

The script SHALL adhere to the project coding standard:

- Executable with `set -euo pipefail`.
- Sources `scripts/_utils.sh` safely.
- Separates private functions by concern:
  - `_install_cli_tools`
  - `_install_hardware_tools`
  - `_install_filesystem_tools`
  - `_install_session_tools`
  - `_install_spelling_dictionaries`
  - `_initialize_xdg_dirs`
- Contains an execution guard (`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`) to permit sourcing in Bats unit tests without running automatically.

#### Scenario: Repeated execution (idempotency)

- **GIVEN** packages already installed on the system
- **WHEN** `scripts/system/setup-packages.sh` is executed multiple times
- **THEN** execution completes with exit code 0 without errors or re-installing unchanged components
