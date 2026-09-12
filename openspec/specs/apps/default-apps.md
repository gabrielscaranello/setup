# Specification: Default Applications & MIME Handlers (`scripts/apps/setup-default-apps.sh`)

## Purpose

Configures default applications across XDG specifications, GNOME desktop environment, and KDE Plasma desktop environment:

- **Kitty** as the default terminal emulator
- **VLC** as the default video player

---

## Requirements

### Requirement: XDG Standards Configuration for Terminal Emulator

The script SHALL configure `kitty.desktop` in `~/.config/xdg-terminals.list`, register `x-scheme-handler/terminal` via `xdg-mime` if available, and ensure `xdg-terminal-exec` is deployed to `~/.local/bin` and `/usr/local/bin` (via `ensure_xdg_terminal_exec`).

### Requirement: Desktop Environment Specific Configuration for Terminal Emulator

The script SHALL detect the active desktop environment using `get_desktop_environment`:

- **GNOME**: SHALL set `org.gnome.desktop.default-applications.terminal` schema keys `exec='kitty'` and `exec-arg='-e'` via `gsettings` if schema exists.
- **KDE Plasma**: SHALL set `TerminalApplication=kitty` and `TerminalService=kitty.desktop` in `~/.config/kdeglobals` via `kwriteconfig6`, `kwriteconfig5`, or direct file manipulation fallback.
- **Unknown / Unsupported DE**: SHALL skip DE-specific tweaks without error.

### Requirement: Default Video Player Configuration (VLC)

The script SHALL configure `vlc.desktop` as the default handler for video MIME types (`video/mp4`, `video/mkv`, `video/x-matroska`, `video/x-msvideo`, `video/avi`, `video/quicktime`, `video/webm`, `video/x-flv`, `video/mpeg`, `video/ogg`, `video/3gpp`, `video/x-ms-wmv`):

- SHALL invoke `xdg-mime default vlc.desktop <mime>` for each video MIME type when `xdg-mime` is present.
- SHALL guarantee that `~/.config/mimeapps.list` contains the video MIME associations under `[Default Applications]` section idempotently across all distributions and desktop environments.

#### Scenario: Applying defaults on GNOME

- **GIVEN** GNOME desktop session
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** XDG terminal list and GNOME gsettings terminal keys SHALL be configured to `kitty`, and video MIME types SHALL be associated with `vlc.desktop` in `~/.config/mimeapps.list`

#### Scenario: Applying defaults on KDE Plasma

- **GIVEN** KDE Plasma desktop session
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** XDG terminal list and `~/.config/kdeglobals` `[General]` section SHALL contain `TerminalApplication=kitty`, and video MIME types SHALL be associated with `vlc.desktop` in `~/.config/mimeapps.list`

#### Scenario: Applying defaults on unknown environment

- **GIVEN** headless or unrecognized window manager
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** XDG terminal list and video MIME associations in `~/.config/mimeapps.list` SHALL be configured, and DE-specific steps skipped cleanly
