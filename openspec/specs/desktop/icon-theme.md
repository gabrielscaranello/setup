# Setup Custom Icon Theme

## Overview

Automate installation and configuration of the `Papirus-Dark` icon theme on the GNOME desktop environment, including `papirus-folders` utility integration to set the folder icon color to the `adwaita` blue variant across supported distributions.

## Requirements

### Desktop Environment Support

- **GNOME**: Installs theme packages/assets, configures folder icon color (`adwaita`) via `papirus-folders`, and sets GNOME preferences via `gsettings` (`org.gnome.desktop.interface icon-theme`).
- **Cinnamon**: Installs theme packages/assets, installs Catppuccin Papirus folder colors, sets folder icon color (`cat-mocha-lavender`) via `papirus-folders`, and sets Cinnamon preferences via `gsettings` and `dconf` (`org.cinnamon.desktop.interface icon-theme`).
- **Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than supported desktop environments (`gnome`, `cinnamon`), the script must **NOT** install or configure anything, and must gracefully exit 0.

### Icon Theme Package (`papirus-icon-theme`)

- **Debian / LMDE (`debian`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.
- **Fedora (`fedora`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.
- **Arch Linux (`arch`)**: Installs native `papirus-icon-theme` package via `install_packages papirus-icon-theme`.

### Folder Color Utility (`papirus-folders` and Catppuccin Assets)

- **Arch Linux (`arch`)**: Installs `papirus-folders` via `install_packages papirus-folders`.
- **Debian / Fedora**: Installs official upstream script from `PapirusDevelopmentTeam/papirus-folders` into `/usr/local/bin` (or `~/.local/bin` if permissions require).
- **Catppuccin Papirus Folders**: When the selected folder color starts with `cat-` (such as `cat-mocha-lavender` on Cinnamon), downloads and deploys Catppuccin folder assets from `catppuccin/papirus-folders` into Papirus icon directories.
- **Upstream Update Check**: When `papirus-folders` is already installed from upstream, checks GitHub API for newer releases and updates automatically.
- **Folder Variant**: Runs `papirus-folders -C <color>` (with `sudo` if `/usr/share/icons` is not user-writable) using `adwaita` on GNOME and `cat-mocha-lavender` on Cinnamon.

### Desktop Preferences Configuration

- **GNOME**: Sets `org.gnome.desktop.interface icon-theme "Papirus-Dark"`.
- **Cinnamon**: Sets `org.cinnamon.desktop.interface icon-theme "Papirus-Dark"` via `gsettings` and `dconf`.

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

**Scenario: Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `cinnamon`
- **WHEN** `setup-icon-theme.sh` is executed
- **THEN** it should install `papirus-icon-theme` and `papirus-folders`
- **AND** install Catppuccin Papirus folder assets
- **AND** apply `papirus-folders -C cat-mocha-lavender`
- **AND** configure Cinnamon icon-theme to "Papirus-Dark" via `gsettings` and `dconf`

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
