# Setup Custom Cursor Theme

## Overview

Automate installation and configuration of the modern `Bibata-Modern-Ice` cursor theme across supported Desktop Environments (GNOME and KDE Plasma).

## Requirements

### Desktop Environment Support

- **GNOME**: Configures cursor theme and size via `gsettings` (`org.gnome.desktop.interface cursor-theme` and `cursor-size`).
- **KDE Plasma**: Configures cursor theme and size via `kwriteconfig6` / `kwriteconfig5` in `kcminputrc`, configures XDG `default/index.theme`, and invokes `kapplymousetheme` if available.
- **Unknown / Unsupported DE**: Per project governance, when `get_desktop_environment` returns `unknown` or an unsupported desktop environment, the script must **NOT** install or guess configurations, and must gracefully exit 0.

### Upstream Assets & Installation

- **Asset**: `Bibata-Modern-Ice.tar.xz` from `https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz`.
- **Target Directories**:
  - System-wide: `/usr/share/icons/Bibata-Modern-Ice` (when running as root or with `sudo`).
  - User-level fallback: `$HOME/.local/share/icons/Bibata-Modern-Ice` and `$HOME/.icons/Bibata-Modern-Ice`.
- **Idempotency**: If the cursor files are already extracted and installed, skips re-downloading and only ensures settings are applied.

## Test Scenarios

### Feature: Cursor Theme Setup

**Scenario: Unsupported or unknown Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `unknown`
- **WHEN** `setup-cursor-theme.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without installing or downloading assets

**Scenario: GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **WHEN** `setup-cursor-theme.sh` is executed
- **THEN** it should download and install `Bibata-Modern-Ice`
- **AND** configure `gsettings` cursor-theme to "Bibata-Modern-Ice"
- **AND** configure `gsettings` cursor-size to 20

**Scenario: KDE Plasma Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma`
- **WHEN** `setup-cursor-theme.sh` is executed
- **THEN** it should download and install `Bibata-Modern-Ice`
- **AND** configure `kcminputrc` via `kwriteconfig6` or `kwriteconfig5`
- **AND** configure XDG default cursor theme
- **AND** apply mouse theme if `kapplymousetheme` is available

**Scenario: Idempotent Execution**

- **GIVEN** `Bibata-Modern-Ice` is already present in target directory
- **WHEN** `setup-cursor-theme.sh` is executed again
- **THEN** it should skip re-downloading the archive
- **AND** complete with exit code 0
