# Specification: Cinnamon Desktop Environment Preferences (`scripts/desktop/setup-cinnamon.sh`)

## Purpose

Configures desktop preferences, theme integration, keyboard shortcuts, and file manager settings for the **Cinnamon** desktop environment (primarily on Linux Mint and LMDE), ensuring a cohesive dark-mode developer experience.

---

## Requirements

### Requirement: Desktop Environment Guard & Skip Policy

The script SHALL detect the current desktop environment using `get_desktop_environment`:

- When `get_desktop_environment` returns `cinnamon`, the script SHALL proceed with Cinnamon configuration.
- When `get_desktop_environment` returns any other value (e.g. `gnome`, `plasma`, `unknown`), the script SHALL log an informational message and exit cleanly with return code `0`.

#### Scenario: Running on non-Cinnamon environment

- **GIVEN** desktop environment is `gnome` or `plasma`
- **WHEN** `scripts/desktop/setup-cinnamon.sh` executes
- **THEN** it SHALL exit with code 0 without modifying Cinnamon settings

#### Scenario: Running on active Cinnamon environment

- **GIVEN** desktop environment is `cinnamon`
- **WHEN** `scripts/desktop/setup-cinnamon.sh` executes
- **THEN** it SHALL apply Cinnamon interface, keybinding, terminal, and Nemo preferences

---

### Requirement: Interface & Dark Mode Configuration

The script SHALL configure dark mode and interface parameters through `gsettings` under active D-Bus session:

- `org.cinnamon.desktop.interface gtk-theme`: set to `'Mint-Y-Dark-Aqua'`.
- `org.cinnamon.desktop.wm.preferences theme`: set to `'Mint-Y-Dark-Aqua'`.
- `org.cinnamon.theme name`: set to `'Mint-Y-Dark-Aqua'`.
- `org.cinnamon.desktop.interface color-scheme`: set to `'prefer-dark'`.
- `org.x.apps.portal color-scheme`: set to `'prefer-dark'`.
- `org.cinnamon.desktop.interface clock-show-date`: set to `true`.
- `org.cinnamon.desktop.interface clock-show-seconds`: set to `false`.
- `org.cinnamon.desktop.interface gtk-enable-primary-paste`: set to `false`.

#### Scenario: Applying dark mode preferences

- **GIVEN** Cinnamon environment
- **WHEN** `_configure_cinnamon_interface` executes
- **THEN** `color-scheme` in `org.cinnamon.desktop.interface` and `org.x.apps.portal` SHALL be set to `'prefer-dark'`

---

### Requirement: Default Terminal Emulator Configuration

The script SHALL configure the default terminal emulator for Cinnamon:

- When `kitty` is installed and available in PATH, `org.cinnamon.desktop.default-applications.terminal exec` SHALL be set to `'kitty'`.
- Otherwise, it SHALL fall back to `'x-terminal-emulator'`.

#### Scenario: Configuring Kitty as default terminal

- **GIVEN** `kitty` is available in PATH
- **WHEN** `_configure_cinnamon_terminal` executes
- **THEN** `org.cinnamon.desktop.default-applications.terminal exec` SHALL be set to `'kitty'`

---

### Requirement: Custom Keybindings Configuration

The script SHALL register custom keybindings for developer productivity:

- Configure custom shortcut for Flameshot GUI screenshot tool (`<Primary><Super>s`, `<Shift><Super>s`, `Print`).

#### Scenario: Configuring Flameshot keybinding

- **GIVEN** Cinnamon environment
- **WHEN** `_configure_cinnamon_keybindings` executes
- **THEN** custom shortcut for `flameshot gui` SHALL be registered in `org.cinnamon.desktop.keybindings`

---

### Requirement: Nemo File Manager Preferences

The script SHALL configure user preferences for the Nemo file manager:

- Desktop volumes: `org.nemo.desktop volumes-visible` set to `false`.
- View mode: `org.nemo.preferences default-folder-viewer` set to `'icon-view'`.
- Hidden files: `org.nemo.preferences show-hidden-files` set to `true`.
- Date format: `org.nemo.preferences date-format` set to `'iso'`.

#### Scenario: Configuring Nemo preferences

- **GIVEN** Cinnamon environment
- **WHEN** `_configure_nemo` executes
- **THEN** Nemo preferences for icon-view, show-hidden-files, and iso date format SHALL be persisted

---

### Requirement: Cinnamon Configuration Templates (`config/cinnamon`)

The script SHALL copy repository configuration templates from `config/cinnamon` into the target user configuration directory (`$HOME/.config/cinnamon`):

- Preserves all spices presets and backgrounds directory.
- Dynamically resolves user home path inside `backgrounds/user-folders.lst`.

#### Scenario: Seeding Cinnamon configuration templates

- **GIVEN** `config/cinnamon` exists in the repository
- **WHEN** `_copy_cinnamon_config` executes
- **THEN** template files and spices configurations SHALL be copied into `$HOME/.config/cinnamon`

---

### Requirement: Cinnamon Desktop Modular dconf Configuration

The script SHALL load Cinnamon desktop dconf preferences from modular configuration files under `config/cinnamon` using `load_dconf_files`:

- `interface.dconf`: Configures interface fonts, clock settings, accessibility, and portal preferences.
- `gtk.dconf`: Configures GTK file-chooser sorting, path-bar location mode, and menu icons.
- `peripherals.dconf`: Configures mouse/touchpad flat acceleration profile, keyboard repeat rate/delay, accessibility, and Bluetooth power manager.
- `window-manager.dconf`: Configures titlebar buttons (`:close`), middle-click minimization, Flameshot shortcut (`<Primary><Super>s`, `<Shift><Super>s`, `Print`), workspace switching, and Muffin window placement/tiling.
- `night-light.dconf`: Configures night light schedule (`4700K`) and power management/sleep timeouts.
- `privacy.dconf`: Configures privacy settings (disabling recent files history).
- `nemo.dconf`: Configures Nemo file manager (icon-view, show hidden files, ISO dates, hiding desktop volume icons).
- `shell.dconf`: Configures Cinnamon panels (height `36px`), zone icon sizes, applet layout, coverflow alt-tab switcher, hot corners, gestures, notifications, screensaver, and silent sound theme.
- `apps.dconf`: Configures Linux Mint update manager, default calculator, Xed editor plugins, and system monitor.

#### Scenario: Loading Cinnamon modular dconf preferences

- **GIVEN** modular `.dconf` files exist in `config/cinnamon`
- **WHEN** `_load_cinnamon_dconf` executes
- **THEN** it SHALL call `load_dconf_files` with all 9 configuration files in `CINNAMON_DCONF_FILES`

---

### Requirement: Cinnamon Panel and Menu Favorite Applications

The script SHALL configure Cinnamon panel pinned applications (`grouped-window-list@cinnamon.org`) matching the canonical order defined across GNOME and KDE Plasma:

1. Nemo file manager (`nemo.desktop`)
2. Kitty terminal (`kitty.desktop`)
3. Code editor (`codium.desktop`)
4. Firefox (`firefox.desktop`)
5. Chromium (`org.chromium.Chromium.desktop:flatpak`)
6. DBeaver (`io.dbeaver.DBeaverCommunity.desktop:flatpak`)
7. ONLYOFFICE (`org.onlyoffice.desktopeditors.desktop:flatpak`)
8. Obsidian (`md.obsidian.Obsidian.desktop:flatpak`)
9. GIMP (`org.gimp.GIMP.desktop:flatpak`)
10. Telegram (`org.telegram.desktop.desktop`)
11. Steam (`com.valvesoftware.Steam.desktop:flatpak`)
12. Discord (`com.discordapp.Discord.desktop:flatpak`)

Flatpak applications SHALL be formatted with the `:flatpak` suffix as required by Cinnamon's desktop menu parser (`gmenu-desktopappinfo.c`).

Start Menu favorite applications (`/org/cinnamon/favorite-apps`) SHALL be cleared (`@as []`) to eliminate duplicate launcher icons between the panel taskbar and the start menu favorites pane.

#### Scenario: Configuring Cinnamon favorite applications

- **GIVEN** desktop environment is Cinnamon
- **WHEN** `configure_cinnamon_favorite_apps` executes
- **THEN** it SHALL clear `/org/cinnamon/favorite-apps` (`@as []`) via dconf and gsettings
- **AND** it SHALL update `pinned-apps` in any `grouped-window-list@cinnamon.org` configuration JSON files with the identical application order
