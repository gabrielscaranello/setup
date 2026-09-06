# Configure Desktop Environment Preferences

## Overview

Automate desktop environment preferences and system application configurations via modular `dconf` dumps across supported distributions (Debian 13, Fedora 44, and Arch Linux).

Currently focused on **GNOME**, with configurations divided into granular `.dconf` files under `config/gnome/` for maintainability, clean diffs, and idempotent application via `dconf load`. Support for other desktop environments (such as KDE Plasma) is deferred to future iterations.

## Requirements

### Desktop Environment Support & Skip Policy

- **Mandatory GNOME Detection**:
  - The script checks the current desktop environment using `get_desktop_environment`.
  - **GNOME Only**: When `get_desktop_environment` returns `gnome`, the script proceeds with loading modular `.dconf` preferences from `config/gnome/`.
- **Non-GNOME Skip Invariant**:
  - Whenever `get_desktop_environment` returns anything other than `gnome` (such as `plasma`, `xfce`, or `unknown`), the script **MUST IMMEDIATELY SKIP** all configuration steps.
  - It outputs an informative log message indicating that GNOME is not the active desktop environment and **exits with return code 0** without modifying any dconf settings, files, or executing system commands.

### Prerequisites

- `dconf` command-line utility available (`dconf load`).
- Fail-fast if `dconf` is not found when running in a GNOME environment.
- Headless / container compatibility: when running in environments without an active session bus (`DBUS_SESSION_BUS_ADDRESS` empty or unset), execution must wrap `dconf` calls with `dbus-run-session` to ensure settings are cleanly written to the user database.

### Modular Configuration Architecture (`config/gnome/`)

Configuration settings are organized into individual `.dconf` dump files within `config/gnome/`:

1. **System Interface & Appearance** (`interface.dconf`):
   - Schema paths: `[org/gnome/desktop/interface]`, `[org/gnome/desktop/datetime]`, `[org/gnome/desktop/sound]`
   - Clock: seconds and weekday display enabled (`clock-show-seconds=true`, `clock-show-weekday=true`).
   - Typography: Cantarell 11 for document and interface font, JetBrainsMono Nerd Font 10 for monospace.
   - Mouse: primary clipboard paste on middle click disabled (`gtk-enable-primary-paste=false`).
   - Timezone: automatic timezone detection enabled (`automatic-timezone=true`).
   - Audio: system event sounds disabled (`event-sounds=false`), freedesktop theme.

2. **Peripherals** (`peripherals.dconf`):
   - Schema paths: `[org/gnome/desktop/peripherals/mouse]`, `[org/gnome/desktop/peripherals/touchpad]`
   - Mouse: flat acceleration profile (`accel-profile='flat'`).
   - Touchpad: two-finger scrolling enabled (`two-finger-scrolling-enabled=true`).

3. **Window Manager & Keybindings** (`window-manager.dconf`):
   - Schema paths: `[org/gnome/desktop/wm/preferences]`, `[org/gnome/desktop/wm/keybindings]`, `[org/gnome/settings-daemon/plugins/media-keys]`, `[.../custom-keybindings/custom0]`, `[.../custom-keybindings/custom1]`
   - Window behavior: middle-clicking the titlebar minimizes the window.
   - Global shortcuts:
     - Show Desktop: `<Super>d`.
     - Open Home Folder: `<Super>e`.
     - Custom Shortcut 0: Terminal -> `<Control><Alt>t` (`kitty`).
     - Custom Shortcut 1: Flameshot -> `<Control><Alt>s` (`flameshot gui`).

4. **Night Light** (`night-light.dconf`):
   - Schema path: `[org/gnome/settings-daemon/plugins/color]`
   - Night light enabled with manual schedule (`night-light-schedule-automatic=false`).
   - Schedule hours: from `4.0` (04:00 AM) to `3.9833333333333334` (~03:59 AM) for continuous protection.
   - Color temperature: 4700K (`uint32 4700`).

5. **Privacy & Search Providers** (`privacy.dconf`):
   - Schema paths: `[org/gnome/desktop/privacy]`, `[org/gnome/desktop/search-providers]`
   - Privacy: recent files maximum age 30 days, `remember-recent-files=false`.
   - Auto-clean: automatic removal of old temp files and trash files enabled.
   - Search providers: disable Clocks, Seahorse, Contacts, and Nautilus from shell search; prioritize Settings, Contacts, and Nautilus in sort order.

6. **Nautilus File Manager** (`nautilus.dconf`):
   - Schema paths: `[org/gnome/nautilus/icon-view]`, `[org/gnome/nautilus/list-view]`, `[org/gnome/nautilus/preferences]`
   - Icon view: default zoom level `small-plus`.
   - List view: tree view navigation enabled (`use-tree-view=true`).
   - Preferences: default folder viewer set to `icon-view`, search filter time type `last_modified`.

7. **Shell, Favorites & App Folders** (`shell.dconf`):
   - Schema paths: `[org/gnome/shell]`, `[org/gnome/desktop/app-folders]`, `[.../folders/*]`
   - Favorite apps in Dash: Nautilus, Kitty, VS Code / VSCodium, Firefox, Chrome, Obsidian, OnlyOffice, GIMP, Discord, Telegram.
   - App picker layout and structured folders:
     - `Games`: ProtonPlus, Steam.
     - `Develop`: DBeaver, MongoDB Compass.
     - `System`: Settings, Tweaks, Disks, Logs, Baobab, etc.
     - `Utilities`: Flameshot, Kitty/Nvim, Extension Manager, Celluloid, Showtime, Loupe, Papers/Evince, etc.

8. **Default GNOME Applications** (`apps.dconf`):
   - Schema paths: `[org/gnome/TextEditor]`, `[org/gnome/gnome-system-monitor]`
   - Text Editor: highlight current line, spaces indentation, dark style scheme (`Adwaita-dark`), use system font, restore session disabled.
   - System Monitor: custom 24-color CPU palette, default tab set to `resources`, processes filter set to `user`.

### Idempotency & Execution Mechanics

- Each `.dconf` file under `config/gnome/` is loaded into the user dconf database using `dconf load / < "$file"`.
- Applying the configurations repeatedly produces the same configuration without side effects or errors.

## Test Scenarios

### Feature: Desktop Environment Preferences

**Scenario: Non-GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma` or `unknown`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should output an informative skip message
- **AND** exit with return code 0 without modifying dconf or any files

**Scenario: Missing dconf Command**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `dconf` is not available in PATH
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should output an error message to stderr
- **AND** exit with a non-zero return code (fail-fast)

**Scenario: Missing Configuration Directory**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** directory `config/gnome/` does not exist or has no `.dconf` files
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should output an error message to stderr
- **AND** exit with a non-zero return code (fail-fast)

**Scenario: Preference Application on GNOME**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `dconf` is available in PATH
- **AND** configuration files exist in `config/gnome/`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should load all `.dconf` files under `config/gnome/` via `dconf load`
- **AND** exit with return code 0

**Scenario: Idempotent Execution**

- **GIVEN** desktop preferences have already been applied to the dconf database
- **WHEN** `setup-desktop-preferences.sh` is executed again
- **THEN** all configurations should be applied cleanly
- **AND** exit with return code 0
