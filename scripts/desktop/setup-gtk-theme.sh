#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_theme_utils.sh" 2> /dev/null || true

THEME_NAME="adw-gtk3-dark"
THEME_LIGHT="adw-gtk3"
FLATPAK_THEMES=("org.gtk.Gtk3theme.adw-gtk3" "org.gtk.Gtk3theme.adw-gtk3-dark")
UPSTREAM_REPO="lassekongo83/adw-gtk3"
CINNAMON_THEME_NAME="Colloid-Dark-Catppuccin"
CINNAMON_THEME_REPO="vinceliuice/Colloid-gtk-theme"

_is_gtk_theme_installed() {
  is_theme_installed "themes" "$THEME_NAME" && is_theme_installed "themes" "$THEME_LIGHT"
}

_get_local_version() {
  get_theme_local_version "themes" "adw-gtk3"
}

_fetch_remote_version() {
  fetch_github_latest_version "$UPSTREAM_REPO"
}

_is_system_package_installed() {
  is_package_installed "adw-gtk3-theme"
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

  deploy_theme_directory "$tmp_dir/adw-gtk3" "themes" "adw-gtk3"
  deploy_theme_directory "$tmp_dir/adw-gtk3-dark" "themes" "adw-gtk3-dark"

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

_ensure_gnome_gtk_theme() {
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
}

_is_cinnamon_theme_installed() {
  is_theme_installed "themes" "$CINNAMON_THEME_NAME"
}

_install_cinnamon_upstream_theme() {
  local version="${1:-}"
  if [ -z "$version" ]; then
    version="$(fetch_github_latest_version "$CINNAMON_THEME_REPO" 2> /dev/null || true)"
  fi

  echo "Installing $CINNAMON_THEME_NAME from upstream..."
  install_packages git sassc || true

  local tmp_dir="/tmp/colloid_theme_$$"
  rm -rf "$tmp_dir"

  if command -v git > /dev/null 2>&1; then
    git clone --depth 1 "https://github.com/${CINNAMON_THEME_REPO}.git" "$tmp_dir"
  else
    local archive_url="https://github.com/${CINNAMON_THEME_REPO}/archive/refs/heads/main.tar.gz"
    local archive_path="/tmp/colloid_$$.tar.gz"
    download_file "$archive_url" "$archive_path"
    mkdir -p "$tmp_dir"
    tar -xzf "$archive_path" -C "$tmp_dir" --strip-components=1
    rm -f "$archive_path"
  fi

  if [ -f "$tmp_dir/install.sh" ]; then
    chmod +x "$tmp_dir/install.sh"
    (cd "$tmp_dir" && ./install.sh -c dark -s standard -l fixed --tweaks catppuccin black rimless) || true
  fi

  if [ -d "$HOME/.themes/$CINNAMON_THEME_NAME" ]; then
    deploy_theme_directory "$HOME/.themes/$CINNAMON_THEME_NAME" "themes" "$CINNAMON_THEME_NAME"
    if [ -n "$version" ]; then
      echo "$version" > "$HOME/.themes/$CINNAMON_THEME_NAME/.version"
      echo "$version" > "$HOME/.local/share/themes/$CINNAMON_THEME_NAME/.version" 2> /dev/null || true
    fi
  fi

  local gtk4_config_dir="$HOME/.config/gtk-4.0"
  mkdir -p "$gtk4_config_dir"
  local source_theme_dir=""
  for dir in "/usr/share/themes/$CINNAMON_THEME_NAME" "$HOME/.local/share/themes/$CINNAMON_THEME_NAME" "$HOME/.themes/$CINNAMON_THEME_NAME"; do
    if [ -d "$dir/gtk-4.0" ]; then
      source_theme_dir="$dir"
      break
    fi
  done

  if [ -n "$source_theme_dir" ]; then
    ln -fs "$source_theme_dir/gtk-4.0/assets" "$gtk4_config_dir/assets" 2> /dev/null || true
    ln -fs "$source_theme_dir/gtk-4.0/gtk.css" "$gtk4_config_dir/gtk.css" 2> /dev/null || true
    ln -fs "$source_theme_dir/gtk-4.0/gtk-dark.css" "$gtk4_config_dir/gtk-dark.css" 2> /dev/null || true
  fi

  rm -rf "$tmp_dir"
}

_ensure_cinnamon_gtk_theme() {
  if ! _is_cinnamon_theme_installed; then
    _install_cinnamon_upstream_theme
  else
    echo "GTK theme '$CINNAMON_THEME_NAME' is already installed."
  fi
}

_configure_cinnamon_gtk_theme() {
  echo "Configuring Cinnamon GTK theme and dark mode..."
  if command -v dconf > /dev/null 2>&1; then
    dconf write /org/cinnamon/desktop/interface/gtk-theme "'$CINNAMON_THEME_NAME'" 2> /dev/null || true
    dconf write /org/cinnamon/desktop/wm/preferences/theme "'$CINNAMON_THEME_NAME'" 2> /dev/null || true
    dconf write /org/cinnamon/theme/name "'$CINNAMON_THEME_NAME'" 2> /dev/null || true
    dconf write /org/cinnamon/desktop/interface/color-scheme "'prefer-dark'" 2> /dev/null || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.cinnamon.desktop.interface gtk-theme "$CINNAMON_THEME_NAME" 2> /dev/null || true
    gsettings set org.cinnamon.desktop.wm.preferences theme "$CINNAMON_THEME_NAME" 2> /dev/null || true
    gsettings set org.cinnamon.theme name "$CINNAMON_THEME_NAME" 2> /dev/null || true
    gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark' 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ] && [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (unsupported or unrecognized). Skipping GTK theme setup."
    return 0
  fi

  case "$de" in
    gnome)
      echo "Setting up $THEME_NAME GTK theme for GNOME..."
      _ensure_gnome_gtk_theme
      _install_flatpak_theme
      _configure_gnome_gtk_theme
      ;;
    cinnamon)
      echo "Setting up $CINNAMON_THEME_NAME GTK theme for Cinnamon..."
      _ensure_cinnamon_gtk_theme
      _configure_cinnamon_gtk_theme
      ;;
  esac

  echo "GTK theme setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
