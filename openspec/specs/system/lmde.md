# Specification: LMDE System Support & Integration

## Purpose

Defines distribution identification, package manager abstraction, system repository integration, desktop environment handling (Cinnamon), default application configuration (VLC player, native Firefox), custom debloat, and core system provisioning for **LMDE 7 (Linux Mint Debian Edition)** based on Debian 13 (Trixie).

This specification establishes LMDE as a first-class supported distribution in the setup catalog, following the project's modular conventions, SOLID design principles, and idempotent execution requirements.

---

## Requirements

### Requirement: Distribution Identification & Detection

The system SHALL identify LMDE through `/etc/os-release` (or `/usr/lib/os-release` via `get_os_release_field`):

- When `ID=linuxmint` and `ID_LIKE` contains `debian`, `get_distro_id` SHALL return `lmde`.
- When `ID=lmde`, `get_distro_id` SHALL return `lmde`.
- `is_distro "lmde"` SHALL return `0`.
- `require_supported_distro` SHALL accept `lmde` and output `lmde` to stdout with exit code `0`.

#### Scenario: Detecting LMDE via `/etc/os-release` with ID_LIKE=debian

- **GIVEN** `/etc/os-release` with `ID=linuxmint` and `ID_LIKE=debian`
- **WHEN** `get_distro_id` is executed
- **THEN** it SHALL output `lmde` and return `0`

#### Scenario: Detecting LMDE via `/etc/os-release` with ID=lmde

- **GIVEN** `/etc/os-release` with `ID=lmde`
- **WHEN** `get_distro_id` is executed
- **THEN** it SHALL output `lmde` and return `0`

#### Scenario: Running `require_supported_distro` on LMDE

- **GIVEN** current distribution is `lmde`
- **WHEN** `require_supported_distro` is executed
- **THEN** it SHALL print `lmde` to stdout and exit with code `0`

---

### Requirement: Package Manager Resolution & Adapter Mapping

The package management subsystem (`scripts/utils/_packages.sh`) SHALL resolve `lmde` to the `apt` package manager adapter targeting the Debian package catalog:

- `_resolve_pm_metadata "lmde"` SHALL return `"apt|2"`, resolving packages via the `DEBIAN` column of `scripts/packages.conf`.
- Package installations SHALL dispatch through `_pm_apt_install`, package removals through `_pm_apt_remove`, and package swaps through `_pm_apt_swap`.
- Package operations SHALL be idempotent, non-interactive, and utilize `sudo apt install -y` or `sudo apt purge -y`.

#### Scenario: Resolving package manager metadata for LMDE

- **GIVEN** LMDE system (`lmde`)
- **WHEN** `_resolve_pm_metadata "lmde"` is called
- **THEN** it SHALL return `"apt|2"` with exit code `0`

#### Scenario: Installing packages idempotently on LMDE

- **GIVEN** LMDE system with package index refreshed
- **WHEN** `install_packages <package_name>` is executed
- **THEN** it SHALL resolve the package name from the Debian column in `packages.conf` and invoke `_pm_apt_install` without user prompting

---

### Requirement: Desktop Environment Identification & Cinnamon Defaults

LMDE uses the **Cinnamon** desktop environment exclusively. Setup scripts SHALL honor Cinnamon conventions and ignore GNOME/Plasma specific configurations:

- When `get_desktop_environment` returns `cinnamon` or when running non-interactively on LMDE, Cinnamon SHALL be the default desktop environment.
- GNOME extensions, GNOME-specific dconf settings, and KDE Plasma kwriteconfig settings SHALL be cleanly bypassed.
- Cinnamon theming (`Mint-Y-Dark-Aqua`), Papirus icon theme with `paleorange` folders, Nemo preferences (icon view, show hidden files), Cinnamon Spices, and custom shortcuts SHALL be applied.

#### Scenario: Resolving default desktop environment for LMDE

- **GIVEN** current distribution is `lmde` and session is non-interactive
- **WHEN** `prompt_desktop_environment` is executed
- **THEN** it SHALL return `cinnamon` with exit code `0`

#### Scenario: Gracefully skipping GNOME extensions on LMDE

- **GIVEN** current distribution is `lmde` and desktop environment is `cinnamon`
- **WHEN** `scripts/desktop/setup-gnome-extensions.sh` is executed
- **THEN** it SHALL gracefully skip GNOME extension installations with exit code `0`

---

### Requirement: Default Applications & Media Handlers

The setup scripts SHALL configure standard desktop application defaults tailored for LMDE:

- **Terminal Emulator:** Kitty SHALL be configured as default terminal via XDG specifications and Cinnamon settings (`org.cinnamon.desktop.default-applications.terminal`).
- **Media Player:** VLC SHALL be configured as the default audio and video player for all supported multimedia MIME types.
- **Web Browser:** Firefox SHALL be installed from the official LMDE distribution repositories without adding any third-party Mozilla APT repository. Chromium SHALL be installed via Flatpak.
- **Office, PDF, Image and Editor:** ONLYOFFICE via Flatpak for office documents, `xreader.desktop` for PDF viewing, `xviewer.desktop` for images, and `xed.desktop` for text editing.

#### Scenario: Setting VLC as default media player on LMDE

- **GIVEN** LMDE system
- **WHEN** `scripts/apps/setup-default-apps.sh` is executed
- **THEN** audio and video MIME types in `~/.config/mimeapps.list` SHALL be associated with `vlc.desktop`

#### Scenario: Installing Firefox from official distro repositories on LMDE

- **GIVEN** current distribution is `lmde`
- **WHEN** `scripts/apps/setup-browsers.sh` is executed
- **THEN** it SHALL install `firefox` from system package repositories and SHALL NOT invoke `add_debian_mozilla_repo`

---

### Requirement: System Debloat Policy for LMDE

The debloat subsystem (`scripts/system/setup-debloat.sh`) SHALL remove default bloatware packages from LMDE installations:

- Packages and patterns marked for removal SHALL include:
  - `celluloid`
  - `gnome-terminal`
  - `hypnotix*`
  - `libreoffice*`
  - `mintchat`
  - `neovim*`
  - `rhythmbox`
  - `simple-scan`
  - `sticky`
  - `thingy`
  - `thunderbird*`
  - `transmission*`
- The system SHALL use pattern expansion via `dpkg-query` to identify and remove all installed matches safely and idempotently.

#### Scenario: Purging debloat packages on LMDE

- **GIVEN** LMDE system with default applications installed
- **WHEN** `scripts/system/setup-debloat.sh` is executed
- **THEN** it SHALL purge matching bloatware packages and autoremove orphaned dependencies

---

### Requirement: Debian Base & Codename Resolution

LMDE pairs Debian base repositories with Linux Mint packages. Repository helpers in `scripts/system/debian/_repositories.sh` SHALL resolve Debian codenames accurately:

- `get_debian_codename` SHALL prioritize `DEBIAN_CODENAME` (`trixie`) over `VERSION_CODENAME` (`gigi`) to prevent invalid repository URLs.
- Debian backports and non-free repository helpers SHALL support `lmde` when configuring hardware graphics drivers.

#### Scenario: Resolving Debian codename on LMDE

- **GIVEN** `/etc/os-release` containing `VERSION_CODENAME=gigi` and `DEBIAN_CODENAME=trixie`
- **WHEN** `get_debian_codename` is executed
- **THEN** it SHALL return `trixie`

---

### Requirement: Runner Orchestration Integration

The orchestration engine (`runners/`) SHALL support end-to-end execution on LMDE:

- A dedicated runner `runners/lmde.sh` SHALL orchestrate common initial steps, system debloat, system packages, desktop environment theming, flatpaks, and developer toolchains.
- `runners/main.sh` SHALL map `lmde` to `runners/lmde.sh` in the `DISTRO_RUNNERS` array.
- `runners/_modules.sh` SHALL expose `lmde` as a standalone execution target.

#### Scenario: Delegating execution from main.sh to LMDE runner

- **GIVEN** system detected as `lmde`
- **WHEN** `./main.sh all` is executed
- **THEN** it SHALL delegate execution to `runners/lmde.sh`
