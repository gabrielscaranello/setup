#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-default-apps.sh logic and functions

@test "_set_default_terminal_xdg creates xdg-terminals.list and calls xdg-mime" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-xdg-home"
  mkdir -p "$test_home"

  local xdg_mime_called=0
  xdg-mime() {
    xdg_mime_called=$((xdg_mime_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "xdg-mime" ]; then return 0; fi
    builtin command "$@"
  }

  HOME="$test_home" _set_default_terminal_xdg

  [ -f "$test_home/.config/xdg-terminals.list" ]
  grep -q "kitty.desktop" "$test_home/.config/xdg-terminals.list"
  [ "$xdg_mime_called" -ge 1 ]
  [ -x "$test_home/.local/bin/xdg-terminal-exec" ]

  rm -rf "$test_home"
}

@test "_set_default_terminal_gnome sets gsettings if schema is present" {
  source /setup/scripts/apps/setup-default-apps.sh
  local gsettings_called=0
  gsettings() {
    if [ "${1:-}" = "list-schemas" ]; then
      echo "org.gnome.desktop.default-applications.terminal"
      return 0
    fi
    if [ "${1:-}" = "set" ]; then
      gsettings_called=$((gsettings_called + 1))
      return 0
    fi
    return 0
  }

  command() {
    if [ "${2:-}" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  _set_default_terminal_gnome
  [ "$gsettings_called" -eq 2 ]
}

@test "_set_default_terminal_plasma uses kwriteconfig6 when available" {
  source /setup/scripts/apps/setup-default-apps.sh
  local kwrite_called=0
  kwriteconfig6() {
    kwrite_called=$((kwrite_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "kwriteconfig6" ]; then return 0; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma6-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ "$kwrite_called" -eq 2 ]
  rm -rf "$test_home"
}

@test "_set_default_terminal_plasma uses kwriteconfig5 when kwriteconfig6 is absent" {
  source /setup/scripts/apps/setup-default-apps.sh
  local kwrite_called=0
  kwriteconfig5() {
    kwrite_called=$((kwrite_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "kwriteconfig6" ]; then return 1; fi
    if [ "${2:-}" = "kwriteconfig5" ]; then return 0; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma5-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ "$kwrite_called" -eq 2 ]
  rm -rf "$test_home"
}

@test "_set_default_terminal_plasma falls back to direct file creation when tools are missing" {
  source /setup/scripts/apps/setup-default-apps.sh
  command() {
    if [ "${2:-}" = "kwriteconfig6" ] || [ "${2:-}" = "kwriteconfig5" ]; then return 1; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma-fallback-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ -f "$test_home/.config/kdeglobals" ]
  grep -q "TerminalApplication=kitty" "$test_home/.config/kdeglobals"
  grep -q "TerminalService=kitty.desktop" "$test_home/.config/kdeglobals"

  rm -rf "$test_home"
}

@test "_set_default_terminal routes only to gnome when de is gnome" {
  source /setup/scripts/apps/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "gnome"; }

  _set_default_terminal

  [ "$gnome_called" -eq 1 ]
  [ "$plasma_called" -eq 0 ]
}

@test "_set_default_terminal routes only to plasma when de is plasma" {
  source /setup/scripts/apps/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "plasma"; }

  _set_default_terminal

  [ "$gnome_called" -eq 0 ]
  [ "$plasma_called" -eq 1 ]
}

@test "_set_default_terminal does not configure gnome or plasma when de is unknown" {
  source /setup/scripts/apps/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "unknown"; }

  _set_default_terminal

  [ "$gnome_called" -eq 0 ]
  [ "$plasma_called" -eq 0 ]
}

@test "_set_default_video_player creates mimeapps.list and sets vlc.desktop" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-vlc-home"
  mkdir -p "$test_home"

  HOME="$test_home" _set_default_video_player

  [ -f "$test_home/.config/mimeapps.list" ]
  grep -q "^\[Default Applications\]" "$test_home/.config/mimeapps.list"
  grep -q "^video/mp4=vlc.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^video/mkv=vlc.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^video/webm=vlc.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_video_player updates existing mimeapps.list idempotently" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-vlc-existing"
  mkdir -p "$test_home/.config"
  cat << 'EOF' > "$test_home/.config/mimeapps.list"
[Default Applications]
text/plain=org.gnome.TextEditor.desktop
video/mp4=totem.desktop;
EOF

  HOME="$test_home" _set_default_video_player

  grep -q "^text/plain=org.gnome.TextEditor.desktop" "$test_home/.config/mimeapps.list"
  grep -q "^video/mp4=vlc.desktop;" "$test_home/.config/mimeapps.list"
  # Should not contain totem for video/mp4
  run grep -q "^video/mp4=totem.desktop" "$test_home/.config/mimeapps.list"
  [ "$status" -ne 0 ]

  rm -rf "$test_home"
}

@test "_set_default_video_player calls xdg-mime when available" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-vlc-xdg"
  mkdir -p "$test_home"

  local xdg_mime_calls=0
  xdg-mime() {
    xdg_mime_calls=$((xdg_mime_calls + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "xdg-mime" ]; then return 0; fi
    builtin command "$@"
  }

  HOME="$test_home" _set_default_video_player

  [ "$xdg_mime_calls" -ge 10 ]
  rm -rf "$test_home"
}

@test "setup-default-apps main runs terminal and video player defaults successfully" {
  source /setup/scripts/apps/setup-default-apps.sh
  _set_default_terminal() { return 0; }
  _set_default_video_player() { return 0; }
  _set_default_audio_player() { return 0; }
  _set_default_web_browser() { return 0; }
  _set_default_office_suite() { return 0; }
  _set_default_pdf_viewer() { return 0; }
  _set_default_image_viewer() { return 0; }
  _set_default_text_editor() { return 0; }
  _set_added_associations() { return 0; }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-default-apps complete" ]]
}

@test "_set_default_audio_player sets vlc.desktop for audio MIME types" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-audio-home"
  mkdir -p "$test_home"

  HOME="$test_home" _set_default_audio_player

  [ -f "$test_home/.config/mimeapps.list" ]
  grep -q "^audio/mpeg=vlc.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^audio/flac=vlc.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^audio/ogg=vlc.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_web_browser sets resolved browser for web schemes and formats" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-browser-home"
  mkdir -p "$test_home"

  resolve_desktop_app() { echo "firefox.desktop"; }

  HOME="$test_home" _set_default_web_browser

  [ -f "$test_home/.config/mimeapps.list" ]
  grep -q "^text/html=firefox.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^x-scheme-handler/http=firefox.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^x-scheme-handler/https=firefox.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_office_suite sets ONLYOFFICE for document, spreadsheet, and presentation formats" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-office-home"
  mkdir -p "$test_home"

  resolve_desktop_app() { echo "org.onlyoffice.desktopeditors.desktop"; }

  HOME="$test_home" _set_default_office_suite

  [ -f "$test_home/.config/mimeapps.list" ]
  grep -q "^application/vnd.openxmlformats-officedocument.wordprocessingml.document=org.onlyoffice.desktopeditors.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=org.onlyoffice.desktopeditors.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^application/vnd.openxmlformats-officedocument.presentationml.presentation=org.onlyoffice.desktopeditors.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_pdf_viewer resolves Evince on GNOME and Okular on Plasma" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-pdf-home"
  mkdir -p "$test_home"

  get_desktop_environment() { echo "gnome"; }
  resolve_desktop_app() { echo "$1"; }

  HOME="$test_home" _set_default_pdf_viewer
  grep -q "^application/pdf=org.gnome.Evince.desktop;" "$test_home/.config/mimeapps.list"

  get_desktop_environment() { echo "plasma"; }
  HOME="$test_home" _set_default_pdf_viewer
  grep -q "^application/pdf=org.kde.okular.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_image_viewer resolves Loupe on GNOME and Gwenview on Plasma" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-image-home"
  mkdir -p "$test_home"

  get_desktop_environment() { echo "gnome"; }
  resolve_desktop_app() { echo "$1"; }

  HOME="$test_home" _set_default_image_viewer
  grep -q "^image/png=org.gnome.Loupe.desktop;" "$test_home/.config/mimeapps.list"

  get_desktop_environment() { echo "plasma"; }
  HOME="$test_home" _set_default_image_viewer
  grep -q "^image/png=org.kde.gwenview.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_default_text_editor resolves TextEditor on GNOME and Kate on Plasma" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-text-home"
  mkdir -p "$test_home"

  get_desktop_environment() { echo "gnome"; }
  resolve_desktop_app() { echo "$1"; }

  HOME="$test_home" _set_default_text_editor
  grep -q "^text/plain=org.gnome.TextEditor.desktop;" "$test_home/.config/mimeapps.list"

  get_desktop_environment() { echo "plasma"; }
  HOME="$test_home" _set_default_text_editor
  grep -q "^text/plain=org.kde.kate.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

@test "_set_added_associations configures secondary associations in mimeapps.list" {
  source /setup/scripts/apps/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-added-home"
  mkdir -p "$test_home"

  resolve_desktop_app() { echo "$1"; }

  HOME="$test_home" _set_added_associations

  [ -f "$test_home/.config/mimeapps.list" ]
  grep -q "^\[Added Associations\]" "$test_home/.config/mimeapps.list"
  grep -q "^x-scheme-handler/https=firefox.desktop;chromium.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^image/png=gimp.desktop;" "$test_home/.config/mimeapps.list"
  grep -q "^text/plain=codium.desktop;" "$test_home/.config/mimeapps.list"

  rm -rf "$test_home"
}

