# Specification: Core Utilities (`scripts/_utils.sh`)

## Purpose

Provides reusable, distribution-agnostic helper functions for system detection, desktop environment detection, root filesystem inspection, package management abstractions, network fetching, and Flatpak application provisioning across Debian, Fedora, and Arch Linux.

The utility architecture adheres to the **Facade Pattern**: `scripts/_utils.sh` acts as an entry point sourcing specialized submodules located under `scripts/utils/`:

- `scripts/utils/_system.sh`: OS distribution, hardware, filesystem, and shell profile utilities.
- `scripts/utils/_packages.sh`: Generic package resolution (`packages.conf`), native package managers, and Flatpak integration.
- `scripts/utils/_desktop.sh`: Desktop environment detection, prompts, and configuration persistence.
- `scripts/utils/_download.sh`: Network downloads, GitHub releases, version checks, and binary installations.
- `scripts/utils/_terminal.sh`: Terminal integration and XDG wrapper scripts (`xdg-terminal-exec`).

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

### Requirement: Desktop Environment Selection & Persistence

The utility functions `save_desktop_environment`, `prompt_desktop_environment`, and `ensure_desktop_environment` SHALL persist user selection and guarantee a valid desktop environment is determined.

#### Scenario: Persisting desktop environment

- **GIVEN** a desktop environment identifier (e.g. `plasma` or `gnome`)
- **WHEN** `save_desktop_environment <de>` is called
- **THEN** it SHALL set `TARGET_DE` in environment and save to `~/.config/setup/desktop-environment`

#### Scenario: Prompting for desktop environment in interactive vs non-interactive mode

- **GIVEN** desktop environment is not active or unknown
- **WHEN** `prompt_desktop_environment` is called interactively
- **THEN** it SHALL prompt the user to choose between KDE Plasma and GNOME
- **AND** when non-interactive, it SHALL return the fallback desktop environment (`plasma` by default)

---

### Requirement: Desktop Application Candidate Resolution

The utility function `resolve_desktop_app` SHALL inspect standard system and user application paths to resolve the first matching `.desktop` entry among provided candidates.

#### Scenario: Resolving candidate desktop application

- **GIVEN** candidate `.desktop` filenames (e.g. `org.mozilla.firefox.desktop` and `firefox.desktop`)
- **WHEN** `resolve_desktop_app` is called
- **THEN** it SHALL check `/usr/share/applications`, `/usr/local/share/applications`, `/var/lib/flatpak/exports/share/applications`, `~/.local/share/flatpak/exports/share/applications`, and `~/.local/share/applications`
- **AND** return the first existing candidate, or fall back to the first argument if none are found

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

---

### Requirement: GitHub Release Version Resolution

The utility function `fetch_github_latest_version` SHALL query the GitHub API for the latest release tag of a repository and fallback to GitHub's HTTP redirect endpoint to remain resilient against API rate limits.

#### Scenario: Resolving latest version tag

- **GIVEN** a GitHub repository slug (`owner/repo`)
- **WHEN** `fetch_github_latest_version <owner/repo>` is called
- **THEN** it SHALL return the latest release tag (e.g. `v0.65.1`) without extra whitespace
- **AND** if the GitHub API returns rate-limit or error, it SHALL fall back to the redirect target of `https://github.com/<owner>/<repo>/releases/latest`

---

### Requirement: Distribution Validation Guard

The utility function `require_supported_distro` SHALL validate that the current operating system is one of `debian`, `fedora`, or `arch`.

#### Scenario: Supported distribution

- **GIVEN** current distribution is `debian`, `fedora`, or `arch`
- **WHEN** `require_supported_distro` is called
- **THEN** it SHALL output the distro ID to stdout and return 0

#### Scenario: Unsupported distribution

- **GIVEN** current distribution is not `debian`, `fedora`, or `arch`
- **WHEN** `require_supported_distro` is called
- **THEN** it SHALL print an error to stderr and return 1

---

### Requirement: Version Comparison Helper

The utility function `is_version_up_to_date` SHALL compare local and remote version strings idempotently.

#### Scenario: Versions match

- **GIVEN** local version equals remote version and neither is empty
- **WHEN** `is_version_up_to_date <local> <remote>` is called
- **THEN** it SHALL return 0

#### Scenario: Versions differ or missing

- **GIVEN** local version is empty or does not equal remote version
- **WHEN** `is_version_up_to_date <local> <remote>` is called
- **THEN** it SHALL return 1

---

### Requirement: Idempotent GitHub Release Binary Installation

The utility function `install_github_binary` SHALL download, extract, and install a single binary from a GitHub release tarball into `/usr/local/bin` idempotently.

#### Scenario: Installing release binary

- **GIVEN** a tool name, repo slug, version, archive file name, and binary name
- **WHEN** `install_github_binary <name> <repo> <version> <file_name> <bin_name>` is called
- **THEN** it SHALL download the archive using `download_file`
- **AND** extract the archive into a temporary folder
- **AND** install the target binary to `/usr/local/bin/<bin_name>`
- **AND** clean up all temporary files after installation

---

### Requirement: Distribution Cron Service Activation

The utility function `enable_cron_service` SHALL resolve and activate the distribution-specific cron daemon (`cron` on Debian, `crond` on Fedora, `cronie` on Arch Linux) via `systemctl`.

#### Scenario: Enabling cron daemon on supported distributions

- **GIVEN** `systemctl` is available on the system
- **WHEN** `enable_cron_service` is called without arguments
- **THEN** it SHALL resolve `cron.service` on Debian, `crond.service` on Fedora, and `cronie.service` on Arch Linux
- **AND** enable and start the service idempotently
- **AND** if `systemctl` is unavailable (e.g. containers or chroot), it SHALL skip gracefully with exit code 0

---

### Requirement: GPU Vendor Detection

The utility function `get_gpu_vendor` SHALL inspect physical PCI devices via `lspci` to detect active GPU hardware, supporting environment override via `GPU_VENDOR`.

#### Scenario: GPU vendor detection via lspci

- **GIVEN** `lspci` outputs display controller lines matching NVIDIA, AMD/ATI, or Intel
- **WHEN** `get_gpu_vendor` is called
- **THEN** it SHALL return `nvidia`, `amd`, or `intel` respectively
- **AND** if no physical GPU matches, it SHALL return `unknown`
- **AND** if `GPU_VENDOR` is exported in the environment, it SHALL honor the override value
