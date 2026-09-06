# Configure GNOME Extensions

## Overview

Automate the configuration and customization of installed GNOME Shell extensions via modular `dconf` dumps across supported distributions (Debian 13, Fedora 44, and Arch Linux).

Each extension's settings are isolated into dedicated `.dconf` files under `config/gnome-extensions/`, enabling modular maintainability, clean version control diffs, and idempotent application via `dconf load`.

## Requirements

### Desktop Environment Support & Skip Policy

- **Mandatory GNOME Detection**:
  - The script checks the current desktop environment using `get_desktop_environment`.
  - **GNOME Only**: When `get_desktop_environment` returns `gnome`, the script proceeds with applying the modular `dconf` configurations and distribution-tailored extension keys.
- **Non-GNOME Skip Invariant**:
  - Whenever `get_desktop_environment` returns anything other than `gnome` (such as `plasma`, `xfce`, `cinnamon`, or `unknown`), the script **MUST IMMEDIATELY SKIP** all configuration steps.
  - It prints an informative log message indicating that GNOME is not the active desktop environment and **exits with return code 0** without modifying any dconf settings, files, or executing system commands.

### Prerequisites

- `dconf` command-line utility available (`dconf load` and `dconf write`).

### Modular Configuration Architecture (`config/gnome-extensions/`)

Configuration settings are organized into individual `.dconf` dump files within `config/gnome-extensions/`:

#### Common Extension Configurations (All Supported Distributions)

1. **Alphabetical App Grid** (`alphabetical-app-grid.dconf`):
   - Schema path: `[org/gnome/shell/extensions/alphabetical-app-grid]`
   - `folder-order-position='end'`
   - `sort-folder-contents=true`

2. **Blur my Shell** (`blur-my-shell.dconf`):
   - Schema paths: `[org/gnome/shell/extensions/blur-my-shell]`, `[.../appfolder]`, `[.../applications]`, `[.../coverflow-alt-tab]`, `[.../dash-to-dock]`, `[.../dash-to-panel]`, `[.../hidetopbar]`, `[.../lockscreen]`, `[.../overview]`, `[.../panel]`, `[.../screenshot]`
   - Preserves blur pipelines and aesthetic styling across GNOME Shell components.

3. **Caffeine** (`caffeine.dconf`):
   - Schema path: `[org/gnome/shell/extensions/caffeine]`
   - `show-indicator='only-active'`
   - `restore-state=true`
   - `duration-timer=2`
   - `countdown-timer=0`
   - `indicator-position-max=2`

4. **Coverflow Alt-Tab** (`coverflow-alt-tab.dconf`):
   - Schema path: `[org/gnome/shell/extensions/coverflowalttab]`
   - `switcher-style='Coverflow'`
   - `switcher-looping-method='Flip Stack'`
   - `position='Bottom'`
   - `preview-to-monitor-ratio=0.9`
   - `animation-time=0.25`
   - `dim-factor=0.5`
   - `hide-panel=true`
   - `icon-style='Overlay'`
   - `overlay-icon-size=128.0`

5. **Logo Menu Base** (`logo-menu.dconf`):
   - Schema path: `[org/gnome/shell/extensions/Logo-menu]`
   - `menu-button-terminal='kitty'`
   - `menu-button-icon-size=20`
   - `menu-button-icon-click-type=1`
   - `hide-softwarecentre=true`
   - `symbolic-icon=true`
   - `use-custom-icon=false`

6. **Status Tray** (`status-tray.dconf`):
   - Schema path: `[org/gnome/shell/extensions/status-tray]`
   - `icon-mode='original'`

7. **Top Bar Organizer** (`top-bar-organizer.dconf`):
   - Schema path: `[org/gnome/shell/extensions/top-bar-organizer]`
   - Panel box ordering:
     - `left-box-order=['LogoMenu', 'vitalsMenu', 'activities']`
     - `center-box-order=['dateMenu']`
     - `right-box-order`: status tray, media/screen recording, and quick settings indicators.

8. **Vitals** (`vitals.dconf`):
   - Schema path: `[org/gnome/shell/extensions/vitals]`
   - `alphabetize=true`
   - `fixed-widths=true`
   - `hide-icons=false`
   - `hot-sensors=['_memory_usage_', '_processor_usage_', '_temperature_k10temp_tctl_']`
   - `position-in-panel=0`
   - `show-storage=false`
   - `show-system=false`
   - `update-time=2`

#### Distribution-Specific Adaptations

1. **Logo Menu Distribution Icon (`menu-button-icon-image`)**:
   - Evaluated dynamically via `get_distro_id`:
     - **Debian (`debian`)**: icon index `2` (Debian logo).
     - **Fedora (`fedora`)**: icon index `1` (Fedora logo).
     - **Arch Linux (`arch`)**: icon index `6` (Arch Linux logo).

2. **Arch Linux Updates Indicator (`arch-update.dconf`)**:
   - Loaded exclusively when `is_distro "arch"` is true.
   - Schema path: `[org/gnome/shell/extensions/arch-update]`
   - Configured without `yay` (using native `pacman` and `checkupdates`):
     - `check-cmd="/bin/sh -c \"/usr/bin/checkupdates; /usr/bin/flatpak remote-ls --columns=application -a --updates\""`
     - `update-cmd='kitty --start-as=maximized --title "Update packages" -1 sh -c "sudo pacman -Syu; flatpak update; echo Done - Press enter to exit; read"'`
     - `check-interval=60`
     - `always-visible=true`
     - `disable-parsing=true`
     - `linkify-menu=false`
     - `package-info-cmd='xdg-open https://www.archlinux.org/packages/%2$s/%3$s/%1$s'`
     - `strip-versions=false`
     - `use-buildin-icons=true`

### Idempotency & Execution Mechanics

- Dconf files are imported using `dconf load / < "$dump_file"`.
- Distribution-specific keys are updated using `dconf write <path> <value>`.
- Re-running the script produces identical settings without duplicate entries or error states.

## Test Scenarios

### Feature: GNOME Extensions Configuration

**Scenario: Non-GNOME Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `plasma` or `unknown`
- **WHEN** `setup-gnome-extensions-config.sh` is executed
- **THEN** it should output a skip message
- **AND** exit with return code 0 without modifying dconf or any files

**Scenario: Missing dconf Command**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `dconf` is not available in PATH
- **WHEN** `setup-gnome-extensions-config.sh` is executed
- **THEN** it should output an error message to stderr
- **AND** exit with a non-zero return code (fail-fast)

**Scenario: Extension Configuration on Debian**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `debian`
- **WHEN** `setup-gnome-extensions-config.sh` is executed
- **THEN** it should load all common `.dconf` dumps
- **AND** set Logo Menu icon to `2`
- **AND** skip loading `arch-update.dconf`
- **AND** exit with return code 0

**Scenario: Extension Configuration on Fedora**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `fedora`
- **WHEN** `setup-gnome-extensions-config.sh` is executed
- **THEN** it should load all common `.dconf` dumps
- **AND** set Logo Menu icon to `1`
- **AND** skip loading `arch-update.dconf`
- **AND** exit with return code 0

**Scenario: Extension Configuration on Arch Linux**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **AND** `get_distro_id` returns `arch`
- **WHEN** `setup-gnome-extensions-config.sh` is executed
- **THEN** it should load all common `.dconf` dumps
- **AND** set Logo Menu icon to `6`
- **AND** load `arch-update.dconf` (configured with `pacman` and `checkupdates`, without `yay`)
- **AND** exit with return code 0

**Scenario: Idempotent Execution**

- **GIVEN** GNOME extension configurations have already been loaded into dconf
- **WHEN** `setup-gnome-extensions-config.sh` is executed again
- **THEN** all configurations should be applied cleanly
- **AND** exit with return code 0
