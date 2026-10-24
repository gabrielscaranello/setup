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
- View mode: `org.nemo.preferences default-folder-viewer` set to `'list-view'`.
- Date format: `org.nemo.preferences date-format` set to `'iso'`.

#### Scenario: Configuring Nemo preferences

- **GIVEN** Cinnamon environment
- **WHEN** `_configure_nemo` executes
- **THEN** Nemo preferences for list-view and iso date format SHALL be persisted
