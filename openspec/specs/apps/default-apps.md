# Specification: Default Applications & MIME Handlers (`scripts/setup-default-apps.sh`)

## Purpose
Configures Kitty as the default terminal emulator across XDG specifications, GNOME desktop environment, and KDE Plasma desktop environment.

---

## Requirements

### Requirement: XDG Standards Configuration
The script SHALL configure `kitty.desktop` in `~/.config/xdg-terminals.list` and register `x-scheme-handler/terminal` via `xdg-mime` if available.

### Requirement: Desktop Environment Specific Configuration
The script SHALL detect the active desktop environment using `get_desktop_environment`:
- **GNOME**: SHALL set `org.gnome.desktop.default-applications.terminal` schema keys `exec='kitty'` and `exec-arg='-e'` via `gsettings` if schema exists.
- **KDE Plasma**: SHALL set `TerminalApplication=kitty` and `TerminalService=kitty.desktop` in `~/.config/kdeglobals` via `kwriteconfig6`, `kwriteconfig5`, or direct file manipulation fallback.
- **Unknown / Unsupported DE**: SHALL skip DE-specific tweaks without error.

#### Scenario: Applying defaults on GNOME
- **GIVEN** GNOME desktop session
- **WHEN** `scripts/setup-default-apps.sh` runs
- **THEN** XDG terminal list and GNOME gsettings terminal keys SHALL be configured to `kitty`

#### Scenario: Applying defaults on KDE Plasma
- **GIVEN** KDE Plasma desktop session
- **WHEN** `scripts/setup-default-apps.sh` runs
- **THEN** XDG terminal list and `~/.config/kdeglobals` `[General]` section SHALL contain `TerminalApplication=kitty`

#### Scenario: Applying defaults on unknown environment
- **GIVEN** headless or unrecognized window manager
- **WHEN** `scripts/setup-default-apps.sh` runs
- **THEN** XDG terminal list SHALL be written and DE-specific steps skipped cleanly
