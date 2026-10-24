# Specification: Cinnamon Spices Setup (`scripts/desktop/setup-cinnamon-spices.sh`)

## Purpose

Installs, configures, and enables essential Cinnamon Spices (applets and extensions) from the official Linux Mint Spices repository, specifically:

- **Color Picker applet** (`color-picker@fmete`): Quick desktop color sampler with notification and shortcut.
- **Transparent Panels extension** (`transparent-panels-reloaded@marcelovbcfilho`): Semi-transparent / transparent panel styling for a modern desktop look.

---

## Requirements

### Requirement: Desktop Environment Guard & Skip Policy

The script SHALL detect the current desktop environment using `get_desktop_environment`:

- When `get_desktop_environment` returns `cinnamon`, the script SHALL proceed with Cinnamon Spices installation and configuration.
- When `get_desktop_environment` returns any other value (e.g. `gnome`, `plasma`, `unknown`), the script SHALL log an informational message and exit cleanly with return code `0`.

#### Scenario: Running on non-Cinnamon environment

- **GIVEN** desktop environment is `gnome` or `plasma`
- **WHEN** `scripts/desktop/setup-cinnamon-spices.sh` executes
- **THEN** it SHALL exit with code 0 without modifying Cinnamon Spices

#### Scenario: Running on Cinnamon environment

- **GIVEN** desktop environment is `cinnamon`
- **WHEN** `scripts/desktop/setup-cinnamon-spices.sh` executes
- **THEN** it SHALL download, extract, configure, and enable target applets and extensions

---

### Requirement: Spices Download & Extraction

The script SHALL idempotently download and extract spices into their canonical user locations:

- Applets: `$HOME/.local/share/cinnamon/applets/<uuid>`
- Extensions: `$HOME/.local/share/cinnamon/extensions/<uuid>`

#### Scenario: Installing Color Picker applet

- **GIVEN** `color-picker@fmete` applet
- **WHEN** spice installation executes
- **THEN** it SHALL fetch `https://cinnamon-spices.linuxmint.com/files/applets/color-picker@fmete.zip` and extract it into `$HOME/.local/share/cinnamon/applets/`

#### Scenario: Installing Transparent Panels extension

- **GIVEN** `transparent-panels-reloaded@marcelovbcfilho` extension
- **WHEN** spice installation executes
- **THEN** it SHALL fetch `https://cinnamon-spices.linuxmint.com/files/extensions/transparent-panels-reloaded@marcelovbcfilho.zip` and extract it into `$HOME/.local/share/cinnamon/extensions/`

---

### Requirement: Cinnamon GSettings Enablement

The script SHALL enable installed applets and extensions in Cinnamon desktop configuration:

- Append `transparent-panels-reloaded@marcelovbcfilho` to `org.cinnamon enabled-extensions` if not already present.
- Append `panel1:right:0:color-picker@fmete:<id>` to `org.cinnamon enabled-applets` if not already present.

#### Scenario: Enabling applets and extensions

- **GIVEN** applet and extension files are installed
- **WHEN** enablement functions execute
- **THEN** `enabled-extensions` and `enabled-applets` SHALL contain their respective UUIDs

---

### Requirement: Cinnamon Spices JSON Configuration

The script SHALL deploy developer preferences for installed spices:

- Color Picker: `$HOME/.config/cinnamon/spices/color-picker@fmete/color-picker@fmete.json` with hex format and `<Primary><Alt>p` keybinding.
- Transparent Panels: `$HOME/.config/cinnamon/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json` with `panel-transparent-with-shadow` and `panel-bottom: true`.

#### Scenario: Deploying spice configuration files

- **GIVEN** destination directories exist under `$HOME/.config/cinnamon/spices/`
- **WHEN** configuration deployment executes
- **THEN** JSON settings files SHALL be written with valid configuration syntax
