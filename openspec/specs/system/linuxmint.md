# Specification: Linux Mint System Support & Integration

## Purpose

Defines distribution identification, package manager abstraction, system repository integration, no-snap preservation, desktop environment discovery (Cinnamon), and core system provisioning for **Linux Mint** (Ubuntu LTS base).

This specification establishes Linux Mint as a first-class supported distribution in the setup catalog, following the project's modular conventions, SOLID design principles, and idempotent execution requirements.

---

## Requirements

### Requirement: Distribution Identification & Detection

The system SHALL identify Linux Mint through `/etc/os-release` (or `/usr/lib/os-release` via `get_os_release_field`):

- When `ID=linuxmint` and `ID_LIKE` contains `ubuntu`, `get_distro_id` SHALL return `linuxmint`.
- `is_distro "linuxmint"` SHALL return `0`.
- `require_supported_distro` SHALL accept `linuxmint` and output `linuxmint` to stdout with exit code `0`.

#### Scenario: Detecting Linux Mint via `/etc/os-release`

- **GIVEN** `/etc/os-release` with `ID=linuxmint` and `ID_LIKE=ubuntu`
- **WHEN** `get_distro_id` is executed
- **THEN** it SHALL output `linuxmint` and return `0`

#### Scenario: Running `require_supported_distro` on Linux Mint

- **GIVEN** current distribution is `linuxmint`
- **WHEN** `require_supported_distro` is executed
- **THEN** it SHALL print `linuxmint` to stdout and exit with code `0`

---

### Requirement: Package Manager Resolution & Adapter Mapping

The package management subsystem (`scripts/utils/_packages.sh`) SHALL resolve `linuxmint` to the `apt` package manager adapter:

- `_resolve_pm_metadata "linuxmint"` SHALL return `"apt|<column>"`, dispatching package installations through `_pm_apt_install`, package removals through `_pm_apt_remove`, and package swaps through `_pm_apt_swap`.
- Package installation SHALL be idempotent, non-interactive, and utilize `sudo apt install -y`.
- Packages SHALL be resolved via `scripts/packages.conf` mapping table.

#### Scenario: Resolving package manager metadata for Linux Mint

- **GIVEN** Linux Mint system (`linuxmint`)
- **WHEN** `_resolve_pm_metadata "linuxmint"` is called
- **THEN** it SHALL return `"apt|..."` with exit code `0`

#### Scenario: Installing packages idempotently on Linux Mint

- **GIVEN** Linux Mint system with package index refreshed
- **WHEN** `install_packages <package_name>` is executed
- **THEN** it SHALL resolve the package name and invoke `_pm_apt_install` without user prompting

---

### Requirement: No-Snap Policy Preservation

Linux Mint natively disables and blocks `snapd` through APT pinning. The setup scripts SHALL preserve and validate this policy:

- The setup scripts SHALL respect Linux Mint's native `/etc/apt/preferences.d/nosnap.pref` policy.
- The setup scripts SHALL NOT attempt to install `snapd` or snap packages.
- All desktop applications and dev tools SHALL be provisioned as native `.deb` packages (from `packages.linuxmint.com` / Ubuntu repositories) or Flatpaks via Flathub.

#### Scenario: Preserving no-snap APT pinning on Linux Mint

- **GIVEN** Linux Mint installation
- **WHEN** setup scripts run
- **THEN** `/etc/apt/preferences.d/nosnap.pref` SHALL remain active and `snapd` SHALL NOT be installed

---

### Requirement: Desktop Environment Identification (Cinnamon)

The desktop detection utility (`scripts/utils/_desktop.sh`) SHALL identify **Cinnamon** as an official desktop environment:

- When `$XDG_CURRENT_DESKTOP` or `$DESKTOP_SESSION` contains `cinnamon` or `X-Cinnamon` (case-insensitive), `get_desktop_environment` SHALL return `cinnamon`.
- When Cinnamon is active, desktop-specific configuration modules (theming, font rendering, keybindings, Nemo settings) SHALL target Cinnamon schemas (`org.cinnamon.*`, `org.nemo.*`).
- When running in headless or non-Cinnamon sessions, desktop configurations SHALL gracefully bypass or prompt without failing.

#### Scenario: Detecting active Cinnamon desktop

- **GIVEN** environment variable `XDG_CURRENT_DESKTOP="X-Cinnamon"`
- **WHEN** `get_desktop_environment` is executed
- **THEN** it SHALL output `cinnamon` and return `0`

#### Scenario: Graceful bypass on unknown or headless environment

- **GIVEN** environment variable `XDG_CURRENT_DESKTOP="unknown"`
- **WHEN** Cinnamon-specific configuration executes
- **THEN** it SHALL skip environment-specific settings cleanly with exit code `0`

---

### Requirement: System Repositories & Tooling Integration

Third-party repositories and developer tooling for Linux Mint SHALL align with Mint's package architecture:

- Docker CE repository SHALL use the upstream Ubuntu suite (`noble` on Mint 22.x).
- Visual Studio Code / VSCodium SHALL be configured via official repository or `.deb` packages.
- Papirus icon theme and `papirus-folders` SHALL be provisioned natively via APT or upstream script.
- The system update step (`upgrade_system`) SHALL refresh `apt update -qq` and perform `apt upgrade -y`.

#### Scenario: System upgrade on Linux Mint

- **GIVEN** Linux Mint distribution
- **WHEN** `upgrade_system` is called
- **THEN** it SHALL execute `sudo apt update -qq` followed by `sudo apt upgrade -y`

---

### Requirement: Runner Orchestration Integration

The orchestration engine (`runners/`) SHALL support end-to-end execution on Linux Mint:

- A dedicated runner `runners/linuxmint.sh` SHALL orchestrate common initial steps, system debloat, system packages, desktop environment theming, flatpaks, and developer toolchains.
- `runners/main.sh` SHALL map `linuxmint` to `runners/linuxmint.sh` in the `DISTRO_RUNNERS` array.

#### Scenario: Delegating execution from main.sh to linuxmint runner

- **GIVEN** system detected as `linuxmint`
- **WHEN** `./main.sh all` is executed
- **THEN** it SHALL delegate execution to `runners/linuxmint.sh`
