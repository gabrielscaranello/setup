# Setup GNOME Extensions

## Overview

Automate the downloading, installation, updating, and activation of essential GNOME Shell extensions via the official GNOME Extensions API (`extensions.gnome.org`) and the native `gnome-extensions` CLI across supported distributions (Debian 13, Fedora 44, and Arch Linux).

## Requirements

### Desktop Environment Support & Skip Policy

- **Mandatory GNOME Detection**:
  - The script checks the current desktop environment using `get_desktop_environment`.
  - **GNOME Only**: When `get_desktop_environment` returns `gnome`, the script proceeds with detecting the GNOME Shell version via `gnome-shell --version` (extracting major version, e.g. 47, 48), querying the official GNOME Extensions API, installing missing or updated extensions, and enabling them.
- **Non-GNOME Skip Invariant**:
  - Whenever `get_desktop_environment` returns anything other than `gnome` (such as `plasma`, `xfce`, `cinnamon`, or `unknown`), the script **MUST IMMEDIATELY SKIP** all extension processing.
  - It prints an informative log message indicating that GNOME is not the active desktop environment and **exits with return code 0** without modifying any user files, running package manager commands, querying the network API, or executing `gnome-extensions`.

### Prerequisites

- `gnome-shell` and `gnome-extensions` command line tool available.
- `curl` or `wget` for downloading extension archives (handled via `_utils.sh` helpers).
- Python 3 with `json` module or `grep`/`sed` fallback for parsing GNOME Extensions API responses.

### Target Extension Catalog

#### Common Extensions (All Supported Distributions)

1. **Alphabetical App Grid** (ID: `4269`, UUID: `AlphabeticalAppGrid@stuarthayhurst`)
2. **Blur my Shell** (ID: `3193`, UUID: `blur-my-shell@aunetx`)
3. **Caffeine** (ID: `517`, UUID: `caffeine@patapon.info`)
4. **Color Picker** (ID: `3396`, UUID: `color-picker@tuberry`)
5. **Copyous** (ID: `8834`, UUID: `copyous@boerdereinar.dev`)
6. **Coverflow Alt-Tab** (ID: `97`, UUID: `CoverflowAltTab@palatis.blogspot.com`)
7. **Emoji Copy** (ID: `6242`, UUID: `emoji-copy@felipeftn`)
8. **Hide Activities Button** (ID: `744`, UUID: `Hide_Activities@shay.shayel.org`)
9. **Logo Menu** (ID: `4451`, UUID: `logomenu@aryan_k`)
10. **Status Tray** (ID: `9164`, UUID: `status-tray@keithvassallo.com`)
11. **Top Bar Organizer** (ID: `4356`, UUID: `top-bar-organizer@julian.gse.jsts.xyz`)
12. **Vitals** (ID: `1460`, UUID: `Vitals@CoreCoding.com`)

#### Distribution-Specific Extensions

- **Arch Linux (`arch`)**:
  - **Arch Linux Updates Indicator** (ID: `1010`, UUID: `arch-update@RaphaelRochet`): Included only when `is_distro arch` is true.

### API Integration & Installation Mechanics

- **API Endpoint**: `https://extensions.gnome.org/extension-info/?pk=<ID>&shell_version=<major>`
- **Native Installation**: Uses official `gnome-extensions install --force <archive.zip>`.
- **Activation & Persistence**:
  - For live sessions, calls `gnome-extensions enable <uuid>`.
  - To ensure extensions are activated across TTY/headless installations, VM provisioning, and upon initial desktop login, the script synchronizes enabled extension UUIDs into the dconf database (`/org/gnome/shell/enabled-extensions`) and GSettings (`org.gnome.shell enabled-extensions`) without duplicating existing entries, and explicitly sets `disable-user-extensions` to `false`.

### Idempotency & Automatic Updates

- For each extension, check if it is already installed locally by inspecting `~/.local/share/gnome-shell/extensions/<uuid>/metadata.json`.
- If installed, compare local `version` against remote API `version`:
  - If `local_version < remote_version`: Download new version, install with `--force`, and re-enable.
  - If `local_version == remote_version`: Skip download and verify extension is enabled.
- If not installed: Download archive from `download_url`, install, and enable.
- Upon completion, the script prints an informational notice reminding users that on Wayland sessions, logging out and logging back in is required for newly installed extensions to take effect.

## Test Scenarios

### Feature: GNOME Extensions Setup

**Scenario: Non-GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma` or `unknown`
- **WHEN** `setup-gnome-extensions.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without installing or enabling any extension

**Scenario: Missing GNOME Shell or Undetermined Version**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `gnome-shell` is not found in PATH or version cannot be determined
- **WHEN** `setup-gnome-extensions.sh` is executed
- **THEN** it should output an error message to stderr
- **AND** exit with a non-zero return code (fail-fast)

**Scenario: GNOME Desktop Environment on Debian or Fedora**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `debian` or `fedora`
- **WHEN** `setup-gnome-extensions.sh` is executed
- **THEN** it should install and enable the 12 common extensions
- **AND** persist the enabled extension UUIDs in dconf and GSettings
- **AND** set `disable-user-extensions` to `false`
- **AND** skip Arch Linux Updates Indicator (ID: 1010)

**Scenario: GNOME Desktop Environment on Arch Linux**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `arch`
- **WHEN** `setup-gnome-extensions.sh` is executed
- **THEN** it should install and enable the 12 common extensions
- **AND** persist the enabled extension UUIDs in dconf and GSettings
- **AND** set `disable-user-extensions` to `false`
- **AND** install and enable Arch Linux Updates Indicator (ID: 1010)

**Scenario: Idempotent Execution with All Extensions Up-to-Date**

- **GIVEN** all extensions are already installed at the latest version matching the GNOME Extensions API
- **WHEN** `setup-gnome-extensions.sh` is executed again
- **THEN** it should skip redundant downloads
- **AND** ensure all extensions are enabled
- **AND** exit with return code 0

**Scenario: Update Detection for Existing Extension**

- **GIVEN** an extension is installed with an older version tag in `metadata.json`
- **AND** the GNOME Extensions API returns a higher version for the active GNOME Shell
- **WHEN** `setup-gnome-extensions.sh` is executed
- **THEN** it should download the updated version archive
- **AND** update the extension via `gnome-extensions install --force`
- **AND** re-enable the extension
