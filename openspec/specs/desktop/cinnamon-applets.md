# Setup Cinnamon Applets and Extensions (Spices)

## Overview

Automate download and installation of curated Cinnamon Spices (applets and extensions) from the official Linux Mint Cinnamon Spices repository (`https://cinnamon-spices.linuxmint.com/files`), deploying them into standard user directories.

## Requirements

### Desktop Environment Support

- **Cinnamon**: Downloads, extracts, and installs curated Cinnamon applets and extensions, and enables user extensions.
- **Non-Cinnamon / Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than `cinnamon`, the script must **NOT** download or install spices, and must gracefully exit 0.

### Spices Catalog & Upstream Endpoints

- **Upstream Base URL**: `https://cinnamon-spices.linuxmint.com/files`
- **Applets Target Directory**: `$HOME/.local/share/cinnamon/applets`
  - `color-picker@fmete`: Color picker tool for Cinnamon panel (`$HOME/.local/share/cinnamon/applets/color-picker@fmete`)
- **Extensions Target Directory**: `$HOME/.local/share/cinnamon/extensions`
  - `transparent-panels-reloaded@marcelovbcfilho`: Transparent panel styling extension (`$HOME/.local/share/cinnamon/extensions/transparent-panels-reloaded@marcelovbcfilho`)

### Installation & Idempotency

- Ensures prerequisite archive extraction tools (`unzip`) are installed via `install_packages`.
- Downloads zip archive for each spice to a temporary location using `download_file`.
- Extracts archive directly into its respective target directory (`applets` or `extensions`).
- If a spice directory already exists, skips re-downloading to ensure idempotent execution.
- Enables installed extensions in `org.cinnamon enabled-extensions` via `gsettings` and `dconf`.

## Test Scenarios

### Feature: Cinnamon Spices Setup

**Scenario: Non-Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `gnome`, `plasma`, or `unknown`
- **WHEN** `setup-cinnamon-applets.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without downloading or extracting spices

**Scenario: Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `cinnamon`
- **WHEN** `setup-cinnamon-applets.sh` is executed
- **THEN** it should install `unzip` package if missing
- **AND** download and extract `color-picker@fmete` into `$HOME/.local/share/cinnamon/applets/color-picker@fmete`
- **AND** download and extract `transparent-panels-reloaded@marcelovbcfilho` into `$HOME/.local/share/cinnamon/extensions/transparent-panels-reloaded@marcelovbcfilho`
- **AND** enable `transparent-panels-reloaded@marcelovbcfilho` in `enabled-extensions`
- **AND** complete with exit code 0

**Scenario: Idempotent Execution**

- **GIVEN** spices are already installed in target directories
- **WHEN** `setup-cinnamon-applets.sh` is executed again
- **THEN** it should skip redundant downloads
- **AND** complete with exit code 0
