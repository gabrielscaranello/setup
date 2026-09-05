#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

CURSOR_NAME="Bibata-Modern-Ice"
CURSOR_ARCHIVE="${CURSOR_NAME}.tar.xz"
DOWNLOAD_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${CURSOR_ARCHIVE}"
CURSOR_SIZE=20

_is_cursor_installed() {
  if [ -d "/usr/share/icons/$CURSOR_NAME/cursors" ] \
    || [ -d "$HOME/.local/share/icons/$CURSOR_NAME/cursors" ] \
    || [ -d "$HOME/.icons/$CURSOR_NAME/cursors" ]; then
    return 0
  fi
  return 1
}

_install_cursor_files() {
  if _is_cursor_installed; then
    echo "Cursor theme '$CURSOR_NAME' is already installed. Skipping download."
    return 0
  fi

  local tmp_dir="/tmp/bibata_cursor_$$"
  local archive_path="/tmp/${CURSOR_ARCHIVE}"

  rm -rf "$tmp_dir" "$archive_path"
  mkdir -p "$tmp_dir"

  install_packages tar xz-utils || true

  echo "Downloading $CURSOR_NAME cursor theme..."
  download_file "$DOWNLOAD_URL" "$archive_path"

  echo "Extracting cursor archive..."
  tar -xf "$archive_path" -C "$tmp_dir"

  local user_icons_dir="$HOME/.local/share/icons"
  mkdir -p "$user_icons_dir" "$HOME/.icons"
  cp -r "$tmp_dir/$CURSOR_NAME" "$user_icons_dir/"
  ln -sfn "$user_icons_dir/$CURSOR_NAME" "$HOME/.icons/$CURSOR_NAME"

  # Also install system-wide if permissions allow or sudo is non-interactive
  if [ -w "/usr/share/icons" ]; then
    cp -r "$tmp_dir/$CURSOR_NAME" "/usr/share/icons/"
  elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    sudo cp -r "$tmp_dir/$CURSOR_NAME" "/usr/share/icons/" 2> /dev/null || true
  fi

  rm -rf "$tmp_dir" "$archive_path"
}

_configure_gnome_cursor() {
  echo "Configuring GNOME cursor theme..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_NAME" 2> /dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2> /dev/null || true
  fi
}

_configure_plasma_cursor() {
  echo "Configuring KDE Plasma cursor theme..."
  local kw_cmd=""
  if command -v kwriteconfig6 > /dev/null 2>&1; then
    kw_cmd="kwriteconfig6"
  elif command -v kwriteconfig5 > /dev/null 2>&1; then
    kw_cmd="kwriteconfig5"
  fi

  if [ -n "$kw_cmd" ]; then
    "$kw_cmd" --file kcminputrc --group Mouse --key cursorTheme "$CURSOR_NAME" 2> /dev/null || true
    "$kw_cmd" --file kcminputrc --group Mouse --key cursorSize "$CURSOR_SIZE" 2> /dev/null || true
  fi

  # Configure XDG default cursor theme
  local default_icon_dir="$HOME/.icons/default"
  mkdir -p "$default_icon_dir"
  cat << EOF > "$default_icon_dir/index.theme"
[Icon Theme]
Inherits=$CURSOR_NAME
EOF
  ln -sf "$HOME/.icons/$CURSOR_NAME/cursors" "$default_icon_dir/cursors" 2> /dev/null || true

  if command -v kapplymousetheme > /dev/null 2>&1; then
    kapplymousetheme "$CURSOR_NAME" 2> /dev/null || true
  fi
}

_configure_cursor_theme() {
  local de="$1"
  case "$de" in
    gnome)
      _configure_gnome_cursor
      ;;
    plasma)
      _configure_plasma_cursor
      ;;
    *)
      return 0
      ;;
  esac
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ] && [ "$de" != "plasma" ]; then
    echo "Desktop Environment is '$de' (unsupported or unrecognized). Skipping cursor theme setup."
    return 0
  fi

  echo "Setting up $CURSOR_NAME cursor theme for $de..."
  _install_cursor_files
  _configure_cursor_theme "$de"
  echo "Cursor theme setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
