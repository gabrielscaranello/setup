# Configure Desktop Environment Preferences

## Overview

Automate desktop environment preferences and system application configurations across supported distributions (**Debian 13**, **Fedora 44**, and **Arch Linux**).

Supports both primary desktop environments:

- **GNOME**: Configured via modular `dconf` dumps organized under `config/gnome/` applied idempotently via `_dconf.sh`.
- **KDE Plasma 6** (Plasma 6.3 on Debian 13, Plasma 6.7 on Arch Linux and Fedora 44): Configured via granular CLI tools (`kwriteconfig6`, `plasma-apply-colorscheme`) and direct INI configuration merging under `~/.config/` applied idempotently via `_plasma.sh`.

## Requirements

### Desktop Environment Support & Skip Policy

- **Environment Detection**:
  - The script checks the current desktop environment using `get_desktop_environment`.
  - **GNOME**: When `get_desktop_environment` returns `gnome`, the script delegates to GNOME configuration routines.
  - **KDE Plasma**: When `get_desktop_environment` returns `plasma`, the script delegates to KDE Plasma 6 configuration routines.
- **Unsupported DE Skip Invariant**:
  - Whenever `get_desktop_environment` returns an unsupported or unknown environment (such as `xfce`, `cinnamon`, or `unknown`), the script **MUST IMMEDIATELY SKIP** all configuration steps.
  - It outputs an informative log message and **exits with return code 0** without modifying any configuration settings or files.

### 1. GNOME Desktop Environment Preferences

#### Prerequisites

- `dconf` command-line utility available (`dconf load`, `dconf write`).
- Automatic dependency resolution via `install_packages dconf`.
- Headless / container execution wrapper: automatically executes with `dbus-run-session` when `DBUS_SESSION_BUS_ADDRESS` is empty.

#### Modular Configuration Files (`config/gnome/*.dconf`)

1. **Interface & Appearance** (`interface.dconf`):
   - Clock: seconds and weekday display enabled (`clock-show-seconds=true`, `clock-show-weekday=true`).
   - Typography: Cantarell 11 (interface and document), JetBrainsMono Nerd Font 10 (monospace).
   - Mouse: primary clipboard paste on middle-click disabled (`gtk-enable-primary-paste=false`).
   - Timezone: automatic timezone detection enabled (`automatic-timezone=true`).
   - Sounds: event sounds disabled (`event-sounds=false`), theme `freedesktop`.
2. **Peripherals** (`peripherals.dconf`):
   - Mouse: flat acceleration profile (`accel-profile='flat'`).
   - Touchpad: two-finger scrolling enabled (`two-finger-scrolling-enabled=true`).
3. **Window Manager & Keybindings** (`window-manager.dconf`):
   - Titlebar middle click: minimizes window.
   - Global shortcuts: Show Desktop (`<Super>d`), Home Folder (`<Super>e`), Terminal (`<Control><Alt>t` -> `kitty`), Flameshot (`<Control><Alt>s` -> `flameshot gui`).
4. **Night Light** (`night-light.dconf`):
   - Enabled with manual continuous schedule (from 4.0 to ~3.98), temperature 4700K.
5. **Privacy & Search Providers** (`privacy.dconf`):
   - Recent files retention 30 days, `remember-recent-files=false`, auto-clean old temp/trash files.
   - Search providers: disable Clocks, Seahorse, Contacts, Nautilus.
6. **Nautilus File Manager** (`nautilus.dconf`):
   - Default zoom `small-plus`, tree view navigation enabled in list view.
7. **Shell & App Folders** (`shell.dconf`):
   - Dash favorite apps: Nautilus, Kitty, Code, Firefox, Chrome, Obsidian, OnlyOffice, GIMP, Discord, Telegram.
   - App picker folders: Games (`ProtonPlus`, `Steam`), Develop (`DBeaver`, `Compass`), System, Utilities.
8. **Applications** (`apps.dconf`):
   - GNOME Text Editor: highlight current line, space indentation, dark style scheme.
   - System Monitor: custom CPU core colors, resources tab default, user processes filter.

---

### 2. KDE Plasma 6 Desktop Environment Preferences (Approach 2: Granular CLI)

#### Compatibility & Target Platforms

- **Debian 13 (Trixie)**: KDE Plasma 6.3
- **Fedora 44**: KDE Plasma 6.7
- **Arch Linux**: KDE Plasma 6.7

#### Prerequisites & Tooling

- Primary CLI utility: `kwriteconfig6` (provided by `kconfig` on Arch, `kf6-kconfig` on Fedora, and `libkf6config-bin` on Debian 13).
- Theme application utility: `plasma-apply-colorscheme` (provided by `plasma-workspace`).
- Fallback mechanism: In minimal container or headless test environments without `kwriteconfig6`, the configuration routines must safely write or update INI key/value pairs directly in the corresponding `~/.config/<filename>` files.

#### Granular Configuration Specifications

1. **Window Management & Visual Effects (`~/.config/kwinrc`)**:
   - **Titlebar Middle Click**:
     - Group: `[MouseBindings]`
     - Key: `CommandActiveTitlebar2=Minimize`
   - **Night Color (Luz Noturna)**:
     - Group: `[NightColor]`
     - Keys: `Active=true`, `Mode=Constant`, `NightTemperature=4700`
   - **Alt-Tab Task Switcher (Coverflow/Flipswitch)**:
     - Group: `[TabBox]`
     - Key: `LayoutName=flipswitch`
   - **Window Effects**:
     - Group: `[Plugins]`
     - Keys: `blurEnabled=true`, `magiclampEnabled=true`

2. **Peripherals & Mouse Acceleration (`~/.config/kcminputrc`)**:
   - **Mouse Acceleration Profile**:
     - Group: `[Mouse]`
     - Key: `AccelerationProfile=flat`
   - **Touchpad Scrolling**:
     - Group: `[Touchpad]`
     - Key: `TwoFingerScroll=true`

3. **Global Keyboard Shortcuts (`~/.config/kglobalshortcutsrc`)**:
   - **Show Desktop**:
     - Group: `[kwin]`
     - Key: `Show Desktop=Meta+D,Meta+D,Peek at Desktop`
   - **Terminal Emulator (Kitty)**:
     - Group: `[services][kitty.desktop]`
     - Key: `_launch=Ctrl+Alt+T`
   - **File Manager (Dolphin)**:
     - Group: `[services][org.kde.dolphin.desktop]`
     - Key: `_launch=Meta+E`
   - **Screenshot Tool**:
     - Group: `[services][org.flameshot.Flameshot.desktop]`
     - Key: `_launch=Ctrl+Alt+S`

4. **Appearance, Fonts & System Defaults (`~/.config/kdeglobals`)**:
   - **Color Scheme**:
     - Apply `BreezeDark` via `plasma-apply-colorscheme BreezeDark` or set:
     - Group: `[KDE]`
     - Key: `LookAndFeelPackage=org.kde.breezedark.desktop`
   - **Typography**:
     - Group: `[General]`
     - `font=Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1`
     - `fixed=JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1`
   - **Default Terminal Application**:
     - Group: `[General]`
     - Keys: `TerminalApplication=kitty`, `TerminalService=kitty.desktop`

5. **Dolphin File Manager (`~/.config/dolphinrc`)**:
   - Group: `[General]`
   - Key: `RememberOpenedTabs=false`

---

### Idempotency & Execution Mechanics

- Running the script repeatedly produces identical configuration values across all targeted keys without duplicates or errors.
- Any existing non-conflicting user settings in other groups within the `.config` files are preserved.

## Test Scenarios

### Feature: Desktop Environment Preferences

**Scenario: Unsupported Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `unknown` or `xfce`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should output an informative skip message
- **AND** exit with return code 0 without modifying any configuration

**Scenario: GNOME Desktop Environment Preferences Application**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should ensure `dconf` is available
- **AND** load all 8 `.dconf` files from `config/gnome/`
- **AND** exit with return code 0

**Scenario: KDE Plasma 6 Desktop Environment Preferences Application**

- **GIVEN** `get_desktop_environment` returns `plasma`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should configure KWin titlebar middle click to Minimize
- **AND** configure Night Color to constant 4700K
- **AND** configure Alt-Tab task switcher layout to flipswitch
- **AND** configure mouse acceleration profile to flat in kcminputrc
- **AND** configure global shortcuts (Meta+D, Meta+E, Ctrl+Alt+T, Ctrl+Alt+S) in kglobalshortcutsrc
- **AND** configure default terminal to Kitty and interface/monospace fonts in kdeglobals
- **AND** exit with return code 0

**Scenario: Idempotent Execution on KDE Plasma 6**

- **GIVEN** KDE Plasma 6 preferences are already applied
- **WHEN** `setup-desktop-preferences.sh` is executed again
- **THEN** all configurations should remain intact
- **AND** exit with return code 0
