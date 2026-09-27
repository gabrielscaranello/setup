# Cinnamon Desktop Environment Preferences

## Overview

Automate configuration of Cinnamon desktop preferences, ergonomics, window manager (Muffin) behavior, Night Light, hotcorners, Nemo desktop icons, system sounds, and navigation shortcuts using `dconf` and `gsettings`.

## Requirements

### Desktop Environment Support

- **Cinnamon**: Applies comprehensive system preferences via dconf configuration profiles and direct setting commands.
- **Non-Cinnamon / Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than `cinnamon`, the script must **NOT** execute configuration actions and must gracefully exit 0.

### Window Management & Button Layout (`Muffin` & `WM Preferences`)

- **Button Layout**: Configures minimalist titlebar button layout with close button only on the right (`:close`).
- **Titlebar Middle Click**: Configures middle click on titlebars to minimize windows.
- **Window Placement**: Configures Muffin placement mode to `center` so that newly spawned windows open centered on screen.
- **Modal Dialogs**: Attaches modal dialogs to parent windows (`attach-modal-dialogs=true`).
- **Draggable Borders**: Sets draggable border width to 10px and enables tile maximization.

### Night Light (`org.cinnamon.settings-daemon.plugins.color`)

- **Activation**: Enables Night Light color temperature adjustment.
- **Schedule**: Sets manual schedule mode active from 4.0 to 4.0 (24h continuous warmth).
- **Temperature**: Sets comfortable warm color temperature to `4400K`.

### Nemo Desktop Icons (`org.nemo.desktop`)

- **Clean Desktop**: Disables desktop file/folder icon grid (`desktop-layout='false::false'`).
- **Volumes & Orphaned Icons**: Hides mounted volume icons and orphaned launchers on the desktop.

### Hotcorners & Application Switcher (`org.cinnamon`)

- **Hotcorners**: Configures top-left hotcorner to trigger Expo (`expo:true:0`) and bottom-left to trigger Scale (`scale:true:500`).
- **Alt-Tab Switcher**: Configures `coverflow` visual Alt-Tab style with 150ms delay across all workspaces.

### System Sounds & Notifications (`org.cinnamon.sounds` & `notifications`)

- **Sound Effects**: Disables noisy system event sounds (login, logout, notification, plug, unplug, tile, switch).
- **Notifications**: Positions desktop notifications at the bottom of the screen with a 5-second duration.

### Keyboard Navigation & Shortcuts (`org.cinnamon.desktop.keybindings`)

- **Window Maximize**: Maps `<Super>m` and `<Alt>F10` to toggle maximized state.
- **Workspaces**: Configures seamless workspace navigation shortcuts (`<Control><Alt>Left/Right` and `<Super>Page_Up/Down`).
- **Lock Screen**: Configures `<Super>l` and `<Control><Alt>l` for quick lock.

## Test Scenarios

### Feature: Cinnamon Desktop Preferences Configuration

**Scenario: Non-Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `gnome`, `plasma`, or `unknown`
- **WHEN** `setup-cinnamon-preferences.sh` is executed
- **THEN** it outputs a skip message
- **AND** exits with return code 0 without modifying dconf

**Scenario: Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `cinnamon`
- **WHEN** `setup-cinnamon-preferences.sh` is executed
- **THEN** it applies dconf profiles for window manager, Night Light, hotcorners, Nemo, sounds, and shortcuts
- **AND** sets button layout to `:close`
- **AND** centers new windows in Muffin
- **AND** disables desktop icons in Nemo
- **AND** exits with return code 0

**Scenario: Idempotent Execution**

- **GIVEN** Cinnamon desktop preferences are already configured
- **WHEN** `setup-cinnamon-preferences.sh` is executed again
- **THEN** it completes with return code 0 without errors or regressions
