# Hide Unwanted Desktop Applications

## Overview

Automate hiding unwanted or cluttering `.desktop` applications from system application menus across all supported distributions (**Debian 13**, **Fedora 44**, and **Arch Linux**).

Certain developer tools, command-line terminal applications, internal system utilities, and legacy diagnostic tools create desktop menu entries (`.desktop` files) in `/usr/share/applications` that clutter application launchers and grids (GNOME App Grid, KDE Kickoff / Application Launcher).

In compliance with the **XDG Desktop Entry Specification**, this module copies target `.desktop` files into the user's local directory (`${XDG_DATA_HOME:-$HOME/.local/share}/applications/`) and marks them with `NoDisplay=true`.

## Requirements

### 1. Rootless Execution & XDG Standard Compliance

- **No Root / Sudo Required**: The script executes entirely in user space without requiring superuser (`sudo`) privileges.
- **XDG Local Overrides**: Target `.desktop` files found in system paths (`/usr/share/applications` or `/usr/local/share/applications`) are copied to `${XDG_DATA_HOME:-$HOME/.local/share}/applications/`.
- **System Update Resilience**: System updates via package managers (`apt`, `dnf`, `pacman`) cannot overwrite user overrides in `~/.local/share/applications/`.

### 2. Compiled Target Applications

The consolidated list covers unwanted menu entries across Debian, Fedora, and Arch Linux:

- `assistant`: Qt Assistant
- `avahi-discover`: Avahi Zeroconf Discovery
- `bottom`: Bottom terminal system monitor
- `bssh`: Avahi SSH Server Browser
- `bvnc`: Avahi VNC Server Browser
- `cups`: CUPS Web Administration Interface
- `designer`: Qt Designer
- `display-im7.q16`: ImageMagick Display GUI
- `linguist`: Qt Linguist
- `lstopo`: hwloc hardware topology viewer
- `mpv`: mpv media player (CLI player launcher)
- `nm-connection-editor`: Network Connections Editor (redundant with desktop settings)
- `org.gnome.Extensions`: Standalone GNOME Extensions tool (redundant)
- `org.gnome.Tour`: GNOME Tour welcome application
- `qdbusviewer`: Qt D-Bus Viewer
- `qv4l2`: V4L2 Test Utility
- `qvidcap`: V4L2 Video Capture Utility
- `system-config-printer`: Print Settings / Printer configuration GUI (redundant with desktop settings)

> [!NOTE]
> Developer tools with desired desktop menu presence (such as `nvim` and `btop`) must NOT be hidden.

### 3. File Existence Check, Idempotency & Unhide Cleanup

- For each target application:
  - Check if the system `.desktop` file exists in `/usr/share/applications/<app>.desktop` or `/usr/local/share/applications/<app>.desktop`.
  - If the system file does not exist, safely skip it without errors.
  - If it exists, copy it to `${XDG_DATA_HOME:-$HOME/.local/share}/applications/<app>.desktop`.
  - Ensure the destination file is writable by the user (`chmod u+w`), accounting for read-only system files (e.g., `cups.desktop` on Arch Linux).
  - Ensure any existing `NoDisplay=` setting is removed, and set `NoDisplay=true`.
- For applications explicitly excluded from being hidden (e.g., `nvim`, `btop`):
  - If a user override exists in `${XDG_DATA_HOME:-$HOME/.local/share}/applications/<app>.desktop` with `NoDisplay=true`, remove the local file to restore visibility.
- Executing the script multiple times produces identical configuration files and preserves idempotency.

## Test Scenarios

### Feature: Hide Desktop Applications

**Scenario: Hide existing system application**

- **GIVEN** a system `.desktop` file exists in `/usr/share/applications/bottom.desktop`
- **WHEN** `setup-hide-apps.sh` is executed
- **THEN** it should copy the file to `~/.local/share/applications/bottom.desktop`
- **AND** the local file should contain `NoDisplay=true`
- **AND** the exit code should be 0

**Scenario: Gracefully skip non-existent application**

- **GIVEN** a target application `designer.desktop` does NOT exist in `/usr/share/applications/`
- **WHEN** `setup-hide-apps.sh` is executed
- **THEN** it should skip `designer.desktop` without creating a broken file in `~/.local/share/applications/`
- **AND** the exit code should be 0

**Scenario: Idempotent execution**

- **GIVEN** `~/.local/share/applications/bottom.desktop` already has `NoDisplay=true`
- **WHEN** `setup-hide-apps.sh` is executed again
- **THEN** `~/.local/share/applications/bottom.desktop` should remain valid with `NoDisplay=true` without duplicate entries
- **AND** the exit code should be 0

**Scenario: Unhide explicitly excluded applications**

- **GIVEN** a user override exists in `~/.local/share/applications/nvim.desktop` or `btop.desktop` with `NoDisplay=true`
- **WHEN** `setup-hide-apps.sh` is executed
- **THEN** `~/.local/share/applications/nvim.desktop` and `btop.desktop` should be removed to restore visibility
- **AND** `nvim` and `btop` must NOT be present in the hidden apps list
- **AND** the exit code should be 0
