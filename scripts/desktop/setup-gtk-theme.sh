#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

THEME_NAME="adw-gtk3-dark"
THEME_LIGHT="adw-gtk3"
FLATPAK_THEMES=("org.gtk.Gtk3theme.adw-gtk3" "org.gtk.Gtk3theme.adw-gtk3-dark")
UPSTREAM_REPO="lassekongo83/adw-gtk3"

_is_gtk_theme_installed() {
  for theme in "$THEME_NAME" "$THEME_LIGHT"; do
    if [ ! -d "/usr/share/themes/$theme" ] \
      && [ ! -d "$HOME/.local/share/themes/$theme" ] \
      && [ ! -d "$HOME/.themes/$theme" ]; then
      return 1
    fi
  done
  return 0
}

_get_local_version() {
  if [ -f "$HOME/.local/share/themes/adw-gtk3/.version" ]; then
    cat "$HOME/.local/share/themes/adw-gtk3/.version"
  elif [ -f "/usr/share/themes/adw-gtk3/.version" ]; then
    cat "/usr/share/themes/adw-gtk3/.version"
  else
    echo ""
  fi
}

_fetch_remote_version() {
  fetch_url "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" 2> /dev/null \
    | grep '"tag_name"' \
    | head -n 1 \
    | cut -d '"' -f 4 || echo ""
}

_is_system_package_installed() {
  local distro
  distro="$(get_distro_id)"
  case "$distro" in
    fedora)
      rpm -q adw-gtk3-theme > /dev/null 2>&1
      ;;
    arch)
      pacman -Q adw-gtk-theme > /dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

_install_upstream_theme() {
  local version="${1:-}"
  if [ -z "$version" ]; then
    version="$(_fetch_remote_version)"
    if [ -z "$version" ]; then
      version="v6.5"
    fi
  fi

  echo "Installing $THEME_NAME ($version) from upstream release..."
  install_packages curl wget tar xz-utils || true

  local archive_name="adw-gtk3${version}.tar.xz"
  local download_url="https://github.com/${UPSTREAM_REPO}/releases/download/${version}/${archive_name}"
  local tmp_dir="/tmp/adw_gtk3_$$"
  local archive_path="/tmp/${archive_name}"

  rm -rf "$tmp_dir" "$archive_path"
  mkdir -p "$tmp_dir"

  download_file "$download_url" "$archive_path"
  tar -xf "$archive_path" -C "$tmp_dir"

  if [ -d "$tmp_dir/adw-gtk3" ]; then
    echo "$version" > "$tmp_dir/adw-gtk3/.version"
  fi
  if [ -d "$tmp_dir/adw-gtk3-dark" ]; then
    echo "$version" > "$tmp_dir/adw-gtk3-dark/.version"
  fi

  local user_themes_dir="$HOME/.local/share/themes"
  mkdir -p "$user_themes_dir" "$HOME/.themes"

  if [ -d "$tmp_dir/adw-gtk3" ]; then
    cp -r "$tmp_dir/adw-gtk3" "$user_themes_dir/"
    ln -sfn "$user_themes_dir/adw-gtk3" "$HOME/.themes/adw-gtk3"
  fi
  if [ -d "$tmp_dir/adw-gtk3-dark" ]; then
    cp -r "$tmp_dir/adw-gtk3-dark" "$user_themes_dir/"
    ln -sfn "$user_themes_dir/adw-gtk3-dark" "$HOME/.themes/adw-gtk3-dark"
  fi

  # System-wide installation when permissions or sudo allow
  if [ -w "/usr/share/themes" ]; then
    [ -d "$tmp_dir/adw-gtk3" ] && cp -r "$tmp_dir/adw-gtk3" "/usr/share/themes/"
    [ -d "$tmp_dir/adw-gtk3-dark" ] && cp -r "$tmp_dir/adw-gtk3-dark" "/usr/share/themes/"
  elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    [ -d "$tmp_dir/adw-gtk3" ] && sudo cp -r "$tmp_dir/adw-gtk3" "/usr/share/themes/" 2> /dev/null || true
    [ -d "$tmp_dir/adw-gtk3-dark" ] && sudo cp -r "$tmp_dir/adw-gtk3-dark" "/usr/share/themes/" 2> /dev/null || true
  fi

  rm -rf "$tmp_dir" "$archive_path"
}

_install_theme_package() {
  local distro
  distro="$(get_distro_id)"

  case "$distro" in
    fedora | arch)
      echo "Installing GTK theme via package manager ($distro)..."
      install_packages adw-gtk3-theme || _install_upstream_theme
      ;;
    *)
      _install_upstream_theme
      ;;
  esac
}

_install_flatpak_theme() {
  if command -v flatpak > /dev/null 2>&1; then
    for theme_app in "${FLATPAK_THEMES[@]}"; do
      echo "Installing Flatpak GTK theme ($theme_app)..."
      install_flatpak_app "$theme_app"
    done
  fi
}

_configure_gnome_gtk_theme() {
  echo "Configuring GNOME GTK theme and dark mode..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME" 2> /dev/null || true
    gsettings set org.gnome.desktop.wm.preferences theme "$THEME_NAME" 2> /dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ]; then
    echo "Desktop Environment is '$de' (not GNOME). Skipping GTK theme setup."
    return 0
  fi

  echo "Setting up $THEME_NAME GTK theme for GNOME..."

  if ! _is_gtk_theme_installed; then
    _install_theme_package
  elif ! _is_system_package_installed; then
    local local_version remote_version
    local_version="$(_get_local_version)"
    remote_version="$(_fetch_remote_version)"

    if [ -n "$remote_version" ] && [ "$local_version" != "$remote_version" ]; then
      echo "Updating GTK theme from GitHub (${local_version:-unknown} -> $remote_version)..."
      _install_upstream_theme "$remote_version"
    else
      echo "GTK theme '$THEME_NAME' is up to date (${local_version:-latest})."
    fi
  else
    echo "GTK theme '$THEME_NAME' is managed by system package manager."
  fi

  _install_flatpak_theme
  _configure_gnome_gtk_theme

  echo "GTK theme setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
