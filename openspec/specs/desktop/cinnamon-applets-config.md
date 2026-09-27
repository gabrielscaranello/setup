# Cinnamon Panel Layout and Applets Configuration

## Overview

Automate configuration of the Cinnamon desktop bottom panel layout, system tray, applets, and extension preferences using `dconf`/`gsettings` and Cinnamon Spices JSON settings files under `$HOME/.config/cinnamon/spices/`.

## Requirements

### Desktop Environment Support

- **Cinnamon**: Applies panel structure, applet positions, favorites, and detailed applet configuration files.
- **Non-Cinnamon / Unsupported / Unknown DE**: Per project governance, when `get_desktop_environment` returns anything other than `cinnamon`, the script must **NOT** execute configuration actions and must gracefully exit 0.

### Cinnamon Panel Configuration (`org.cinnamon`)

- **Panels**: Configures a single bottom panel (`1:0:bottom`) with height `40` and autohide disabled (`false`).
- **Zone Icon & Text Sizing**: Sets balanced symbolic, standard, and text dimensions for left, center, and right panel zones.
- **Enabled Applets**:
  - **Left Zone**:
    - `menu@cinnamon.org` (instance `0`): Application menu at position 0.
    - `separator@cinnamon.org` (instance `1`): Visual separator at position 1.
    - `grouped-window-list@cinnamon.org` (instance `2`): Window list grouping tasks and pinned applications at position 2.
  - **Right Zone**:
    - `color-picker@fmete` (instance `3`): Color picker shortcut tool at position 0.
    - `xapp-status@cinnamon.org` (instance `4`): XApp status tray icons at position 1.
    - `systray@cinnamon.org` (instance `5`): Standard notification tray at position 2.
    - `inhibit@cinnamon.org` (instance `6`): Power/screensaver inhibitor at position 3.
    - `notifications@cinnamon.org` (instance `7`): System notifications center at position 4.
    - `printers@cinnamon.org` (instance `8`): Printer applet at position 5.
    - `removable-drives@cinnamon.org` (instance `9`): Removable media manager at position 6.
    - `keyboard@cinnamon.org` (instance `10`): Keyboard layout indicator at position 7.
    - `favorites@cinnamon.org` (instance `11`): Quick favorites at position 8.
    - `network@cinnamon.org` (instance `12`): Network status & connections at position 9.
    - `sound@cinnamon.org` (instance `13`): Sound & volume mixer at position 10.
    - `power@cinnamon.org` (instance `14`): Power & battery status at position 11.
    - `calendar@cinnamon.org` (instance `15`): Date & clock applet at position 12.
    - `cornerbar@cinnamon.org` (instance `16`): Show desktop / cornerbar at position 13.
  - **Next Applet ID**: Sets `next-applet-id` to `17`.

### Favorite Applications Integration

- Configures `org.cinnamon favorite-apps` with cross-distribution resolved application launchers via `_favorite_apps.sh`.

### Spices Settings Profiles (`$HOME/.config/cinnamon/spices/`)

- Deploys and persists configuration JSON profiles:
  - `grouped-window-list@cinnamon.org/2.json`: Window grouping enabled, thumbnails enabled, button labels hidden (`title-display`: 1), and pinned apps populated with resolved favorite applications.
  - `color-picker@fmete/color-picker@fmete.json` (and `3.json`): Configures format `HEX-Color` (`"1"`), notifications enabled, and activation keybinding `<Primary><Alt>l::`.
  - `calendar@cinnamon.org/15.json`: Custom format enabled (`%H:%M:%S`) and toggle keybinding `<Super>c`.
  - `transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json`: Transparency mode `panel-transparent-with-shadow` and bottom panel transparency enabled.

## Test Scenarios

### Feature: Cinnamon Panel Layout and Applets Configuration

**Scenario: Non-Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `gnome`, `plasma`, or `unknown`
- **WHEN** `setup-cinnamon-applets-config.sh` is executed
- **THEN** it outputs a skip message
- **AND** exits with code 0 without modifying dconf or user spices configuration

**Scenario: Cinnamon Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `cinnamon`
- **WHEN** `setup-cinnamon-applets-config.sh` is executed
- **THEN** it configures panel settings and enabled-applets in `org.cinnamon`
- **AND** configures `org.cinnamon favorite-apps`
- **AND** writes JSON settings under `$HOME/.config/cinnamon/spices/`
- **AND** exits with code 0

**Scenario: Idempotent Execution**

- **GIVEN** Cinnamon panel and spices configurations are already in place
- **WHEN** `setup-cinnamon-applets-config.sh` is run again
- **THEN** it completes successfully with return code 0
