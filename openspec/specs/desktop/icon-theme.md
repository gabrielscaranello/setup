# Setup Custom Icon Theme

## Overview

Automate installation and configuration of the `Papirus-Dark` icon theme on the GNOME desktop environment, including `papirus-folders` utility integration to set the folder icon color to the `adwaita` blue variant across supported distributions.

## Requirements

### Desktop Environment Support

- **GNOME**: Installs theme packages/assets, configures folder icon color via `papirus-folders`, and sets GNOME preferences via `gsettings`.
- **Non-GNOME / Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than `gnome` (such as `plasma` or `unknown`), the script must **NOT** install or configure anything, and must gracefully exit 0.

### Icon Theme Package (`papirus-icon-theme`)

- **Debian (`debian`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.
- **Fedora (`fedora`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.
- **Arch Linux (`arch`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.

### Folder Color Utility (`papirus-folders`)

- **Arch Linux (`arch`)**: Installs `papirus-folders` via `install_packages papirus-folders`.
- **Debian / Fedora**: Installs official upstream script from `PapirusDevelopmentTeam/papirus-folders` into `/usr/local/bin` (or `~/.local/bin` if permissions require).
- **Upstream Update Check**: When `papirus-folders` is already installed from upstream, checks GitHub API for newer releases and updates automatically.
- **Folder Variant**: Runs `papirus-folders -C adwaita` (with `sudo` if `/usr/share/icons` is not user-writable) to customize folder icons for all Papirus variants.

### GNOME Configuration (`gsettings`)

- Sets `org.gnome.desktop.interface icon-theme "Papirus-Dark"`.

## Test Scenarios

### Feature: Icon Theme Setup

**Scenario: Non-GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma` or `unknown`
- **WHEN** `setup-icon-theme.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without installing packages or configuring themes

**Scenario: GNOME Desktop Environment on Arch Linux**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `arch`
- **WHEN** `setup-icon-theme.sh` is executed
- **THEN** it should install `papirus-icon-theme` and `papirus-folders`
- **AND** apply `papirus-folders -C adwaita`
- **AND** configure GNOME GSettings icon-theme to "Papirus-Dark"

**Scenario: GNOME Desktop Environment on Fedora or Debian**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `fedora` or `debian`
- **WHEN** `setup-icon-theme.sh` is executed
- **THEN** it should install `papirus-icon-theme`
- **AND** install upstream `papirus-folders`
- **AND** apply `papirus-folders -C adwaita`
- **AND** configure GNOME GSettings icon-theme to "Papirus-Dark"

**Scenario: Idempotent Execution**

- **GIVEN** `Papirus-Dark` and `papirus-folders` are already installed and up to date
- **WHEN** `setup-icon-theme.sh` is executed again
- **THEN** it should skip redundant installations
- **AND** complete with exit code 0

**Scenario: Upstream papirus-folders Update Available**

- **GIVEN** `papirus-folders` is installed from upstream with an older version
- **AND** a newer release is detected from GitHub API
- **WHEN** `setup-icon-theme.sh` is executed
- **THEN** it should download and install the newer version of `papirus-folders`
