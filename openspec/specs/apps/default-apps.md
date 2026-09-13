# Specification: Default Applications & MIME Handlers (`scripts/apps/setup-default-apps.sh`)

## Purpose

Configures default applications across XDG specifications, GNOME desktop environment, and KDE Plasma desktop environment:

- **Kitty** as the default terminal emulator
- **VLC** as the default video and audio player
- **Firefox** (with Chromium fallback) as the default web browser
- **ONLYOFFICE** as the default office documents editor
- **Evince** (GNOME) / **Okular** (KDE Plasma) as the default PDF viewer
- **Loupe** (GNOME) / **Gwenview** (KDE Plasma) as the default image viewer
- **GNOME Text Editor** (GNOME) / **Ghostwriter** (KDE Plasma) as the default text editor
- **Added Associations** (`[Added Associations]`) for secondary applications (Chromium, GIMP, VSCodium)

---

## Requirements

### Requirement: XDG Standards Configuration for Terminal Emulator

The script SHALL configure `kitty.desktop` in `~/.config/xdg-terminals.list`, register `x-scheme-handler/terminal` via `xdg-mime` if available, and ensure `xdg-terminal-exec` is deployed to `~/.local/bin` and `/usr/local/bin` (via `ensure_xdg_terminal_exec`).

### Requirement: Desktop Environment Specific Configuration for Terminal Emulator

The script SHALL detect the active desktop environment using `get_desktop_environment`:

- **GNOME**: SHALL set `org.gnome.desktop.default-applications.terminal` schema keys `exec='kitty'` and `exec-arg='-e'` via `gsettings` if schema exists.
- **KDE Plasma**: SHALL set `TerminalApplication=kitty` and `TerminalService=kitty.desktop` in `~/.config/kdeglobals` via `kwriteconfig6`, `kwriteconfig5`, or direct file manipulation fallback.
- **Unknown / Unsupported DE**: SHALL skip DE-specific tweaks without error.

### Requirement: Default Media Players Configuration (VLC)

The script SHALL configure `vlc.desktop` as the default handler for video and audio MIME types:

- **Video**: `video/mp4`, `video/mkv`, `video/x-matroska`, `video/x-msvideo`, `video/avi`, `video/quicktime`, `video/webm`, `video/x-flv`, `video/mpeg`, `video/ogg`, `video/3gpp`, `video/x-ms-wmv`.
- **Audio**: `audio/mpeg`, `audio/mp3`, `audio/mp4`, `audio/flac`, `audio/x-flac`, `audio/wav`, `audio/x-wav`, `audio/aac`, `audio/x-aac`, `audio/ogg`, `audio/x-vorbis+ogg`, `audio/opus`, `audio/m4a`, `audio/x-m4a`, `audio/x-matroska`.
- SHALL invoke `xdg-mime default vlc.desktop <mime>` when `xdg-mime` is present.
- SHALL guarantee that `~/.config/mimeapps.list` contains the MIME associations under `[Default Applications]` section idempotently.

### Requirement: Default Web Browser Configuration (Firefox / Chromium)

The script SHALL configure the web browser handler:

- SHALL resolve the browser desktop file prioritizing `firefox.desktop` or `org.mozilla.firefox.desktop`, falling back to `chromium.desktop` / `org.chromium.Chromium.desktop`.
- SHALL associate web MIME types and schemes: `text/html`, `text/xml`, `application/xhtml+xml`, `application/xml`, `x-scheme-handler/http`, `x-scheme-handler/https`, `x-scheme-handler/about`, `x-scheme-handler/unknown`.
- SHALL register secondary browser associations in `[Added Associations]` under `~/.config/mimeapps.list`.

### Requirement: Default Office Documents Suite (ONLYOFFICE)

The script SHALL configure `org.onlyoffice.desktopeditors.desktop` (or `onlyoffice-desktopeditors.desktop`):

- **Text Documents**: `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `application/vnd.openxmlformats-officedocument.wordprocessingml.template`, `application/vnd.oasis.opendocument.text`, `application/vnd.oasis.opendocument.text-template`, `application/rtf`, `application/x-abiword`, `application/vnd.wordperfect`.
- **Spreadsheets**: `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, `application/vnd.openxmlformats-officedocument.spreadsheetml.template`, `application/vnd.oasis.opendocument.spreadsheet`, `application/vnd.oasis.opendocument.spreadsheet-template`, `text/csv`.
- **Presentations**: `application/vnd.ms-powerpoint`, `application/vnd.openxmlformats-officedocument.presentationml.presentation`, `application/vnd.openxmlformats-officedocument.presentationml.template`, `application/vnd.oasis.opendocument.presentation`, `application/vnd.oasis.opendocument.presentation-template`.

### Requirement: Default Document, Image and Text Handlers

The script SHALL detect the Desktop Environment to configure tailored default viewers:

- **PDF**: `org.gnome.Evince.desktop` on GNOME, `org.kde.okular.desktop` on KDE Plasma for `application/pdf`, `application/x-pdf`.
- **Images**: `org.gnome.Loupe.desktop` on GNOME, `org.kde.gwenview.desktop` on KDE Plasma for `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/bmp`, `image/tiff`, `image/x-png`.
- **Text / Code**: `org.gnome.TextEditor.desktop` on GNOME, `org.kde.ghostwriter.desktop` on KDE Plasma for `text/plain`, `text/markdown`.
- **Added Associations**: Register GIMP (`image/png`, `image/svg+xml`, `image/x-xcf`) and VSCodium (`text/plain`, `text/markdown`) under `[Added Associations]`.

---

## Scenarios

### Scenario: Applying full defaults on GNOME

- **GIVEN** GNOME desktop session
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** Kitty SHALL be set as terminal, VLC for video and audio, Firefox for web, ONLYOFFICE for documents, Evince for PDF, Loupe for images, and Text Editor for text in `~/.config/mimeapps.list`

### Scenario: Applying full defaults on KDE Plasma

- **GIVEN** KDE Plasma desktop session
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** Kitty SHALL be set as terminal (including `kdeglobals`), VLC for video and audio, Firefox for web, ONLYOFFICE for documents, Okular for PDF, Gwenview for images, and Ghostwriter for text in `~/.config/mimeapps.list`

### Scenario: Applying defaults on headless or unrecognized environment

- **GIVEN** headless or unrecognized window manager
- **WHEN** `scripts/apps/setup-default-apps.sh` runs
- **THEN** XDG terminal list and all standard MIME associations in `~/.config/mimeapps.list` SHALL be configured, and DE-specific steps skipped cleanly
