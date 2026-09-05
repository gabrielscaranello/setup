# Specification: Core Utilities (`scripts/_utils.sh`)

## Purpose

Provides reusable, distribution-agnostic helper functions for system detection, desktop environment detection, root filesystem inspection, package management abstractions, network fetching, and Flatpak application provisioning across Debian, Fedora, and Arch Linux.

---

## Requirements

### Requirement: Distribution & Package Manager Detection

The utility library SHALL detect the operating system distribution via `/etc/os-release` (with fallback to `/usr/lib/os-release` and configurable via `OS_RELEASE_PATH` for testing), exposing:
- `get_distro_id`: returns the exact distribution identifier (`debian`, `fedora`, `arch`, or derivative/unsupported IDs)
- `is_distro <id>`: returns 0 if the current distribution matches the specified ID
- `_get_package_manager`: internal helper resolving the package manager command (`apt`, `dnf`, `pacman`) for package execution

All setup scripts and runners SHALL use `get_distro_id` for distribution branching and decision-making, keeping `_get_package_manager` strictly internal to package execution.

#### Scenario: Running on supported distributions

- **GIVEN** `/etc/os-release` indicates `debian`, `fedora`, or `arch`
- **WHEN** `get_distro_id` is invoked
- **THEN** it returns `debian`, `fedora`, or `arch` respectively
- **AND** `_get_package_manager` resolves to `apt`, `dnf`, or `pacman`

#### Scenario: Running on a derivative or unsupported distribution

- **GIVEN** `/etc/os-release` indicates a derivative (e.g., `ubuntu`, `linuxmint`, `manjaro`, `nobara`)
- **WHEN** `get_distro_id` is invoked
- **THEN** it returns the exact identifier (`ubuntu`, `linuxmint`, etc.)
- **AND** setup scripts and runners SHALL fail-fast or bypass foreign actions since they only target `debian`, `fedora`, and `arch`

---

### Requirement: Generic Package Installation & Resolution

The utility function `install_packages` SHALL resolve generic package names against `scripts/packages.conf` and invoke the active package manager non-interactively and idempotently.

#### Scenario: Installing a package mapped in `packages.conf`

- **GIVEN** a package has different names across distributions (e.g., `build-essential` vs `@development-tools` vs `base-devel`)
- **WHEN** `install_packages <generic_name>` is called
- **THEN** the translated package name for the current distro SHALL be passed to the package manager
- **AND** if mapped to `-` (unsupported), the package SHALL be skipped gracefully

#### Scenario: Installing a package not mapped in `packages.conf`

- **GIVEN** a package name is identical across all distributions (fallback behavior)
- **WHEN** `install_packages <package_name>` is called
- **THEN** the exact package name SHALL be passed to the package manager

---

### Requirement: Desktop Environment Detection

The utility function `get_desktop_environment` SHALL detect the active desktop environment based on environment variables (`XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`, `GDMSESSION`).

#### Scenario: Detecting GNOME

- **GIVEN** `XDG_CURRENT_DESKTOP` contains `GNOME`
- **WHEN** `get_desktop_environment` is called
- **THEN** it SHALL return `gnome`

#### Scenario: Detecting KDE Plasma

- **GIVEN** `XDG_CURRENT_DESKTOP` contains `KDE` or `DESKTOP_SESSION` contains `plasma`
- **WHEN** `get_desktop_environment` is called
- **THEN** it SHALL return `plasma`

#### Scenario: Unrecognized or headless environment

- **GIVEN** no known desktop environment variable is present
- **WHEN** `get_desktop_environment` is called
- **THEN** it SHALL return `unknown` without failing

---

### Requirement: Root Filesystem Detection

The utility function `get_root_filesystem` SHALL determine the filesystem type of the root partition (`/`).

#### Scenario: Root is on Btrfs

- **GIVEN** the mount point `/` is formatted with Btrfs
- **WHEN** `get_root_filesystem` is called
- **THEN** it SHALL return `btrfs`

#### Scenario: Root is on ext4

- **GIVEN** the mount point `/` is formatted with ext4
- **WHEN** `get_root_filesystem` is called
- **THEN** it SHALL return `ext4`

---

### Requirement: Idempotent Flatpak App Installation

The utility function `install_flatpak_app` SHALL ensure the Flatpak runtime and Flathub remote are configured before installing the requested application.

#### Scenario: Flatpak remote not configured

- **GIVEN** `flatpak` is installed but `flathub` remote is missing
- **WHEN** `install_flatpak_app <app_id>` is called
- **THEN** the `flathub` remote SHALL be added automatically
- **AND** the requested application SHALL be installed non-interactively

#### Scenario: Application is already installed

- **GIVEN** `<app_id>` is already installed via Flatpak
- **WHEN** `install_flatpak_app <app_id>` is called
- **THEN** the function SHALL return 0 without re-installing or erroring

---

### Requirement: Resilient Remote Fetching

The utility functions `download_file` and `fetch_url` SHALL handle remote HTTP/HTTPS requests with transparent fallback between `curl` and `wget`.

#### Scenario: Downloading a remote file

- **GIVEN** a valid URL and destination path
- **WHEN** `download_file <url> <dest>` is called
- **THEN** it SHALL successfully save the file using `curl` if available, or `wget` as fallback
- **AND** verify that the destination file was created with non-zero size
