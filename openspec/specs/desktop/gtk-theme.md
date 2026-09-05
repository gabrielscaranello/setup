# Setup Custom GTK Theme

## Overview

Automate installation and configuration of the modern `adw-gtk3` theme and its dark variant (`adw-gtk3-dark`) on the GNOME desktop environment, including Flatpak theme runtime integration across all supported distributions.

## Requirements

### Desktop Environment Support

- **GNOME**: Installs theme packages/assets, configures Flatpak theme runtime, and sets GNOME preferences via `gsettings`.
- **Non-GNOME / Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than `gnome` (such as `plasma` or `unknown`), the script must **NOT** install or configure anything, and must gracefully exit 0.

### Theme Assets & Package Management

- **Fedora (`fedora`)**: Installs native `adw-gtk3-theme` package via `install_packages adw-gtk3-theme`.
- **Arch Linux (`arch`)**: Installs native `adw-gtk-theme` package via `install_packages adw-gtk3-theme`.
- **Debian (`debian`)**: Downloads latest upstream release archive (`adw-gtk3*.tar.xz`) from `https://github.com/lassekongo83/adw-gtk3/releases/latest`, extracts, saves version metadata, and installs to `$HOME/.local/share/themes/` (and `/usr/share/themes/` if permissions/sudo allow).
- **Upstream Update Check**: When the theme is already installed via GitHub upstream (or not managed by a system package manager), checks remote releases against the local recorded version and automatically updates if a newer version is available.

### Flatpak Integration

- Installs both light and dark Flathub theme extensions (`org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark`) via `install_flatpak_app` across all distros when running under GNOME, ensuring Flatpak applications have both variants available while adhering to GNOME dark preferences.

### GNOME Configuration (`gsettings`)

- Sets `org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"`.
- Sets `org.gnome.desktop.wm.preferences theme "adw-gtk3-dark"`.
- Sets `org.gnome.desktop.interface color-scheme 'prefer-dark'`.

## Test Scenarios

### Feature: GTK Theme Setup

**Scenario: Non-GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma` or `unknown`
- **WHEN** `setup-gtk-theme.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without installing packages, Flatpak runtimes, or downloading assets

**Scenario: GNOME Desktop Environment on Fedora**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `fedora`
- **WHEN** `setup-gtk-theme.sh` is executed
- **THEN** it should install `adw-gtk3-theme`
- **AND** install Flatpak themes `org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark`
- **AND** configure GNOME GSettings to "adw-gtk3-dark" and "prefer-dark"

**Scenario: GNOME Desktop Environment on Arch Linux**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `arch`
- **WHEN** `setup-gtk-theme.sh` is executed
- **THEN** it should install `adw-gtk-theme`
- **AND** install Flatpak themes `org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark`
- **AND** configure GNOME GSettings to "adw-gtk3-dark" and "prefer-dark"

**Scenario: GNOME Desktop Environment on Debian**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `debian`
- **WHEN** `setup-gtk-theme.sh` is executed
- **THEN** it should download and extract the upstream release
- **AND** install Flatpak themes `org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark`
- **AND** configure GNOME GSettings to "adw-gtk3-dark" and "prefer-dark"

**Scenario: Idempotent Execution**

- **GIVEN** `adw-gtk3-dark` is already installed and up to date
- **WHEN** `setup-gtk-theme.sh` is executed again
- **THEN** it should skip re-downloading/re-installing
- **AND** complete with exit code 0

**Scenario: Upstream Theme Update Available**

- **GIVEN** `adw-gtk3-dark` is installed via GitHub upstream with an older version
- **AND** a newer release is detected from GitHub API
- **WHEN** `setup-gtk-theme.sh` is executed
- **THEN** it should download and install the newer version
- **AND** update the stored version metadata
