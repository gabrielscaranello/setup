# Specification: Desktop Environment Applications Provisioning (`scripts/desktop/setup-desktop-apps.sh`)

## Purpose

Installs the canonical, native desktop applications corresponding to the active Desktop Environment (**KDE Plasma** or **GNOME**) across supported distributions (**Debian 13**, **Fedora 44**, and **Arch Linux**). The suite provides file management, quick-look previewing, archive management, document/image viewing, text editing, calculator, system diagnostics, and disk management tailored to the visual toolkit of the active session.

---

## Requirements

### Requirement: Desktop Environment Detection & Routing

The script SHALL inspect the current desktop environment using `get_desktop_environment` and route installation:

- When `plasma`: SHALL install the curated KDE Plasma application suite via `_install_plasma_apps`.
- When `gnome`: SHALL install the curated GNOME application suite via `_install_gnome_apps`.
- When `unknown` and interactive (`[ -t 0 ]`): SHALL prompt the user to select between KDE Plasma and GNOME, persist the choice via `save_desktop_environment`, and proceed with installation.
- When `unknown` and non-interactive: SHALL report an informative message and exit cleanly with code 0 without attempting desktop-specific package installation.
- When desktop environment is resolved: SHALL persist the environment via `save_desktop_environment`.

#### Scenario: Running under KDE Plasma

- **GIVEN** active desktop environment is `plasma` (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/desktop/setup-desktop-apps.sh` executes
- **THEN** KDE Plasma application suite SHALL be installed
- **AND** desktop environment SHALL be persisted via `save_desktop_environment`

#### Scenario: Running under GNOME

- **GIVEN** active desktop environment is `gnome` (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/desktop/setup-desktop-apps.sh` executes
- **THEN** GNOME application suite SHALL be installed
- **AND** desktop environment SHALL be persisted via `save_desktop_environment`

#### Scenario: Running under unknown environment interactively

- **GIVEN** desktop environment is `unknown` and running in an interactive terminal
- **WHEN** `scripts/desktop/setup-desktop-apps.sh` executes
- **THEN** an interactive prompt SHALL prompt the user to choose Plasma or GNOME
- **AND** the selection SHALL be saved via `save_desktop_environment` and the chosen application suite installed

#### Scenario: Running under unknown or headless environment non-interactively

- **GIVEN** no recognized desktop environment (`get_desktop_environment` returns `unknown`) and non-interactive shell
- **WHEN** `scripts/desktop/setup-desktop-apps.sh` executes
- **THEN** execution terminates immediately with exit code 0 and an informative message

---

### Requirement: KDE Plasma Application Suite Installation

When the detected environment is `plasma`, the script SHALL install the following applications via `install_packages`:

- `dolphin`: Advanced file manager.
- `dolphin-plugins`: Thumbnailers and network sharing extensions (`ffmpegthumbs`, `kdegraphics-thumbnailers`, `kdenetwork-filesharing` on Arch; `ffmpegthumbs` on Debian/Fedora).
- `ark`: Graphical archive manager.
- `gwenview`: Image viewer.
- `okular`: Document and PDF viewer.
- `kalk`: Calculator application.
- `plasma-systemmonitor`: System process and resource monitor.
- `filelight`: Disk usage graphical analyzer.
- `partitionmanager`: Partition editor (`partitionmanager` on Debian/Arch, `kde-partitionmanager` on Fedora).
- `ghostwriter`: Distraction-free markdown text editor.
- `kde-gtk-config`: GTK theme integration module for KDE Plasma (`kde-config-gtk-style` on Debian, `kde-gtk-config` on Fedora/Arch).
- `kdeconnect`: Device integration client (`kdeconnect` on Debian/Arch, `kde-connect` on Fedora).
- `kweather`: Weather forecast application.
- `vlc`: Multi-format media and video player.

#### Scenario: Installing KDE Plasma suite

- **GIVEN** `plasma` environment active across any supported distribution
- **WHEN** `_install_plasma_apps` executes
- **THEN** all specified KDE Plasma packages SHALL be resolved via `packages.conf` and installed via `install_packages`

---

### Requirement: GNOME Application Suite Installation

When the detected environment is `gnome`, the script SHALL install the following applications via `install_packages`:

- `nautilus`: Standard GNOME file manager.
- `sushi`: File quick-look previewer (`gnome-sushi` on Debian, `sushi` on Fedora/Arch).
- `file-roller`: Graphical archive manager (`file-roller` on Debian/Arch, `file-roller` and `file-roller-nautilus` on Fedora).
- `loupe`: Modern GTK4 image viewer.
- `evince`: Document and PDF viewer.
- `gnome-calculator`: Calculator application.
- `gnome-system-monitor`: System process and resource monitor.
- `baobab`: Disk usage graphical analyzer.
- `gnome-disk-utility`: Storage drives and partition manager.
- `gnome-text-editor`: Modern GTK4 text editor.
- `gnome-tweaks`: Advanced configuration and customization utility.
- `extension-manager`: Graphical utility to browse, install, and manage GNOME Shell extensions (installed natively on Arch Linux, and via Flatpak `com.mattjakeman.ExtensionManager` on Debian and Fedora).
- `gnome-weather`: Weather forecast application.
- `vlc`: Multi-format media and video player.

#### Scenario: Installing GNOME suite

- **GIVEN** `gnome` environment active across any supported distribution
- **WHEN** `_install_gnome_apps` executes
- **THEN** all specified GNOME packages SHALL be resolved via `packages.conf` and installed via `install_packages`
- **AND** `com.mattjakeman.ExtensionManager` SHALL be installed via `install_flatpak_app` on Debian and Fedora

---

### Requirement: Idempotency and Script Structure Contract

The script SHALL adhere to the project coding standard:

- Executable with `set -euo pipefail`.
- Sources `scripts/_utils.sh` safely.
- Separates concerns into private functions:
  - `_install_plasma_apps`
  - `_install_gnome_apps`
- Exposes an execution guard (`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`) to permit sourcing in Bats unit tests without automatic execution.

#### Scenario: Re-executing setup

- **GIVEN** applications already installed
- **WHEN** `scripts/desktop/setup-desktop-apps.sh` is executed repeatedly
- **THEN** execution completes with exit code 0 without duplicate operations or errors
