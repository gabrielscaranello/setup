#!/bin/bash

# Default Desktop Applications and MIME Handlers Setup Script
# Configures default application associations across XDG standards, GNOME, and KDE Plasma:
# - Kitty as default terminal emulator (xdg-terminals.list, GNOME gsettings, KDE kdeglobals)
# - VLC for video and audio playback
# - Firefox (Chromium fallback) for web browsing
# - ONLYOFFICE for office documents (Word, Excel, PowerPoint, OpenDocument)
# - Evince (GNOME) / Okular (KDE Plasma) for PDF documents
# - Loupe (GNOME) / Gwenview (KDE Plasma) for images
# - GNOME Text Editor (GNOME) / Ghostwriter (KDE Plasma) for text and markdown files
# - Secondary application handlers under [Added Associations] (Chromium, GIMP, VSCodium)

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_update_mimeapps_key() {
  local file="$1"
  local section="$2"
  local key="$3"
  local val="$4"

  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || touch "$file"

  awk -v sec="[$section]" -v k="$key" -v v="$val" '
    BEGIN { in_sec = 0; replaced = 0; sec_seen = 0; has_lines = 0 }
    /^\[.*\]$/ {
      if (in_sec && !replaced) { print k "=" v; replaced = 1 }
      if ($0 == sec) { in_sec = 1; sec_seen = 1 } else { in_sec = 0 }
    }
    {
      has_lines = 1
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == "") { last_line_blank = 1 } else { last_line_blank = 0 }
      if (in_sec && substr(line, 1, length(k) + 1) == (k "=")) {
        print k "=" v
        replaced = 1
        next
      }
      print
    }
    END {
      if (in_sec && !replaced) { print k "=" v; replaced = 1 }
      if (!sec_seen) {
        if (has_lines && !last_line_blank) { print "" }
        print sec
        print k "=" v
      }
    }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

_set_mime_default() {
  local desktop_file="$1"
  shift
  local mimes=("$@")
  local mimeapps_file="$HOME/.config/mimeapps.list"

  mkdir -p "$HOME/.config"

  local mime
  for mime in "${mimes[@]}"; do
    if command -v xdg-mime > /dev/null 2>&1; then
      xdg-mime default "$desktop_file" "$mime" 2> /dev/null || true
    fi
    _update_mimeapps_key "$mimeapps_file" "Default Applications" "$mime" "${desktop_file};"
  done
}

_set_default_terminal_xdg() {
  local desktop_file="kitty.desktop"

  mkdir -p "$HOME/.config"

  # Standard XDG terminal list specification
  echo "$desktop_file" > "$HOME/.config/xdg-terminals.list"

  # MIME handler for terminal schemes if xdg-mime is available
  if command -v xdg-mime > /dev/null 2>&1; then
    xdg-mime default "$desktop_file" x-scheme-handler/terminal 2> /dev/null || true
  fi

  ensure_xdg_terminal_exec
}

_set_default_terminal_gnome() {
  if ! command -v gsettings > /dev/null 2>&1; then
    return 0
  fi

  # Legacy GNOME schema compatibility
  if gsettings list-schemas 2> /dev/null | grep -qx "org.gnome.desktop.default-applications.terminal"; then
    gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2> /dev/null || true
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2> /dev/null || true
  fi
}

_set_default_terminal_plasma() {
  # KDE Plasma terminal configuration in ~/.config/kdeglobals
  local kdeglobals="$HOME/.config/kdeglobals"

  mkdir -p "$HOME/.config"

  if command -v kwriteconfig6 > /dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2> /dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2> /dev/null || true
  elif command -v kwriteconfig5 > /dev/null 2>&1; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty" 2> /dev/null || true
    kwriteconfig5 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2> /dev/null || true
  else
    # Fallback to direct file modification if kwriteconfig is not present
    if [ -f "$kdeglobals" ]; then
      if grep -q "^\[General\]" "$kdeglobals"; then
        if grep -q "^TerminalApplication=" "$kdeglobals"; then
          sed -i "s|^TerminalApplication=.*|TerminalApplication=kitty|" "$kdeglobals"
        else
          sed -i "/^\[General\]/a TerminalApplication=kitty" "$kdeglobals"
        fi
        if grep -q "^TerminalService=" "$kdeglobals"; then
          sed -i "s|^TerminalService=.*|TerminalService=kitty.desktop|" "$kdeglobals"
        else
          sed -i "/^\[General\]/a TerminalService=kitty.desktop" "$kdeglobals"
        fi
      else
        cat << INNER_EOF >> "$kdeglobals"

[General]
TerminalApplication=kitty
TerminalService=kitty.desktop
INNER_EOF
      fi
    else
      cat << INNER_EOF > "$kdeglobals"
[General]
TerminalApplication=kitty
TerminalService=kitty.desktop
INNER_EOF
    fi
  fi
}

_set_default_terminal() {
  local de
  de="$(get_desktop_environment)"

  echo "Setting Kitty as the default terminal emulator (Desktop environment: $de)..."
  _set_default_terminal_xdg

  case "$de" in
    gnome)
      _set_default_terminal_gnome
      ;;
    plasma)
      _set_default_terminal_plasma
      ;;
    *)
      # For unrecognized desktop environments, do not apply DE-specific configurations
      ;;
  esac

  echo "Default terminal emulator configured successfully."
}

_set_default_video_player() {
  local desktop_file="vlc.desktop"
  local video_mimes=(
    "video/mp4"
    "video/mkv"
    "video/x-matroska"
    "video/x-msvideo"
    "video/avi"
    "video/quicktime"
    "video/webm"
    "video/x-flv"
    "video/mpeg"
    "video/ogg"
    "video/3gpp"
    "video/x-ms-wmv"
  )

  echo "Setting VLC as the default video player..."
  _set_mime_default "$desktop_file" "${video_mimes[@]}"
  echo "Default video player configured successfully."
}

_set_default_audio_player() {
  local desktop_file="vlc.desktop"
  local audio_mimes=(
    "audio/mpeg"
    "audio/mp3"
    "audio/mp4"
    "audio/flac"
    "audio/x-flac"
    "audio/wav"
    "audio/x-wav"
    "audio/aac"
    "audio/x-aac"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/opus"
    "audio/m4a"
    "audio/x-m4a"
    "audio/x-matroska"
  )

  echo "Setting VLC as the default audio player..."
  _set_mime_default "$desktop_file" "${audio_mimes[@]}"
  echo "Default audio player configured successfully."
}

_set_default_web_browser() {
  local desktop_file
  desktop_file="$(resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop" "chromium.desktop" "chromium-browser.desktop" "org.chromium.Chromium.desktop")"

  local browser_mimes=(
    "text/html"
    "text/xml"
    "application/xhtml+xml"
    "application/xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  )

  echo "Setting $desktop_file as the default web browser..."
  _set_mime_default "$desktop_file" "${browser_mimes[@]}"
  echo "Default web browser configured successfully."
}

_set_default_office_suite() {
  local desktop_file
  desktop_file="$(resolve_desktop_app "org.onlyoffice.desktopeditors.desktop" "onlyoffice-desktopeditors.desktop")"

  local office_mimes=(
    "application/msword"
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
    "application/vnd.oasis.opendocument.text"
    "application/vnd.oasis.opendocument.text-template"
    "application/rtf"
    "application/x-abiword"
    "application/vnd.wordperfect"
    "application/vnd.ms-excel"
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
    "application/vnd.oasis.opendocument.spreadsheet"
    "application/vnd.oasis.opendocument.spreadsheet-template"
    "text/csv"
    "application/vnd.ms-powerpoint"
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    "application/vnd.openxmlformats-officedocument.presentationml.template"
    "application/vnd.oasis.opendocument.presentation"
    "application/vnd.oasis.opendocument.presentation-template"
  )

  echo "Setting ONLYOFFICE as the default office documents editor..."
  _set_mime_default "$desktop_file" "${office_mimes[@]}"
  echo "Default office suite configured successfully."
}

_set_default_pdf_viewer() {
  local de
  de="$(get_desktop_environment)"
  local desktop_file

  if [ "$de" = "plasma" ]; then
    desktop_file="$(resolve_desktop_app "org.kde.okular.desktop" "okular.desktop" "org.gnome.Evince.desktop" "evince.desktop")"
  else
    desktop_file="$(resolve_desktop_app "org.gnome.Evince.desktop" "evince.desktop" "org.kde.okular.desktop" "okular.desktop")"
  fi

  local pdf_mimes=(
    "application/pdf"
    "application/x-pdf"
  )

  echo "Setting $desktop_file as the default PDF viewer..."
  _set_mime_default "$desktop_file" "${pdf_mimes[@]}"
  echo "Default PDF viewer configured successfully."
}

_set_default_image_viewer() {
  local de
  de="$(get_desktop_environment)"
  local desktop_file

  if [ "$de" = "plasma" ]; then
    desktop_file="$(resolve_desktop_app "org.kde.gwenview.desktop" "gwenview.desktop" "org.gnome.Loupe.desktop" "eog.desktop")"
  else
    desktop_file="$(resolve_desktop_app "org.gnome.Loupe.desktop" "eog.desktop" "org.kde.gwenview.desktop" "gwenview.desktop")"
  fi

  local image_mimes=(
    "image/jpeg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/tiff"
    "image/x-png"
  )

  echo "Setting $desktop_file as the default image viewer..."
  _set_mime_default "$desktop_file" "${image_mimes[@]}"
  echo "Default image viewer configured successfully."
}

_set_default_text_editor() {
  local de
  de="$(get_desktop_environment)"
  local desktop_file

  if [ "$de" = "plasma" ]; then
    desktop_file="$(resolve_desktop_app "org.kde.ghostwriter.desktop" "ghostwriter.desktop" "org.gnome.TextEditor.desktop" "gedit.desktop")"
  else
    desktop_file="$(resolve_desktop_app "org.gnome.TextEditor.desktop" "gedit.desktop" "org.kde.ghostwriter.desktop" "ghostwriter.desktop")"
  fi

  local text_mimes=(
    "text/plain"
    "text/markdown"
  )

  echo "Setting $desktop_file as the default text editor..."
  _set_mime_default "$desktop_file" "${text_mimes[@]}"
  echo "Default text editor configured successfully."
}

_set_added_associations() {
  local mimeapps_file="$HOME/.config/mimeapps.list"
  local firefox_desktop chromium_desktop gimp_desktop editor_desktop

  firefox_desktop="$(resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
  chromium_desktop="$(resolve_desktop_app "chromium.desktop" "chromium-browser.desktop" "org.chromium.Chromium.desktop")"
  gimp_desktop="$(resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
  editor_desktop="$(resolve_desktop_app "codium.desktop" "code-oss.desktop")"

  local browser_combo="${firefox_desktop};${chromium_desktop};"
  local browser_mimes=(
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "text/html"
    "application/xhtml+xml"
  )

  echo "Configuring secondary application associations in Added Associations..."
  for mime in "${browser_mimes[@]}"; do
    _update_mimeapps_key "$mimeapps_file" "Added Associations" "$mime" "$browser_combo"
  done

  local image_mimes=(
    "image/png"
    "image/svg+xml"
    "image/x-xcf"
  )
  for mime in "${image_mimes[@]}"; do
    _update_mimeapps_key "$mimeapps_file" "Added Associations" "$mime" "${gimp_desktop};"
  done

  _update_mimeapps_key "$mimeapps_file" "Added Associations" "text/plain" "${editor_desktop};"
  _update_mimeapps_key "$mimeapps_file" "Added Associations" "text/markdown" "${editor_desktop};"

  echo "Added associations configured successfully."
}

main() {
  echo "Configuring default desktop applications..."
  _set_default_terminal
  _set_default_video_player
  _set_default_audio_player
  _set_default_web_browser
  _set_default_office_suite
  _set_default_pdf_viewer
  _set_default_image_viewer
  _set_default_text_editor
  _set_added_associations
  echo "setup-default-apps complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
