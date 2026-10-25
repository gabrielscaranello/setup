#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_theme_utils.sh" 2> /dev/null || true

THEME_NAME="Papirus-Dark"
DEFAULT_FOLDER_COLOR="adwaita"
FOLDER_COLOR="${FOLDER_COLOR:-}"
FOLDERS_UPSTREAM_REPO="PapirusDevelopmentTeam/papirus-folders"

_is_icon_theme_installed() {
  is_theme_installed "icons" "$THEME_NAME"
}

_is_system_icon_package_installed() {
  is_package_installed "papirus-icon-theme"
}

_install_icon_package() {
  echo "Installing icon theme package (papirus-icon-theme)..."
  install_packages papirus-icon-theme
}

_ensure_icon_theme() {
  if ! _is_icon_theme_installed; then
    _install_icon_package
  elif _is_system_icon_package_installed; then
    echo "Icon theme '$THEME_NAME' is managed by system package manager."
  else
    echo "Icon theme '$THEME_NAME' is already installed."
  fi
}

_is_papirus_folders_installed() {
  command -v papirus-folders > /dev/null 2>&1 || [ -x "$HOME/.local/bin/papirus-folders" ]
}

_get_local_papirus_folders_version() {
  if command -v papirus-folders > /dev/null 2>&1; then
    papirus-folders -V 2> /dev/null | awk '{print $2}' || echo ""
  elif [ -f "$HOME/.local/bin/papirus-folders" ]; then
    "$HOME/.local/bin/papirus-folders" -V 2> /dev/null | awk '{print $2}' || echo ""
  elif [ -f "/usr/local/bin/papirus-folders" ]; then
    "/usr/local/bin/papirus-folders" -V 2> /dev/null | awk '{print $2}' || echo ""
  else
    echo ""
  fi
}

_fetch_remote_papirus_folders_version() {
  fetch_github_latest_version "$FOLDERS_UPSTREAM_REPO"
}

_is_system_papirus_folders_installed() {
  is_package_installed "papirus-folders"
}

_install_papirus_folders_upstream() {
  local version="${1:-}"
  if [ -z "$version" ]; then
    version="$(_fetch_remote_papirus_folders_version)"
    if [ -z "$version" ]; then
      version="master"
    fi
  fi

  echo "Installing papirus-folders ($version) from upstream..."
  local script_url="https://raw.githubusercontent.com/${FOLDERS_UPSTREAM_REPO}/${version}/papirus-folders"
  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/papirus-folders.XXXXXX")"
  local tmp_script="${tmp_dir}/papirus-folders"

  if ! download_file "$script_url" "$tmp_script"; then
    rm -rf "$tmp_dir"
    return 1
  fi
  chmod +x "$tmp_script"

  local target_bin="/usr/local/bin/papirus-folders"
  if [ -w "/usr/local/bin" ]; then
    cp "$tmp_script" "$target_bin"
  elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    sudo cp "$tmp_script" "$target_bin" 2> /dev/null || true
  else
    mkdir -p "$HOME/.local/bin"
    cp "$tmp_script" "$HOME/.local/bin/papirus-folders"
  fi

  rm -rf "$tmp_dir"
}

_ensure_papirus_folders() {
  if ! _is_papirus_folders_installed; then
    local distro
    distro="$(get_distro_id)"
    case "$distro" in
      arch)
        echo "Installing papirus-folders via package manager ($distro)..."
        install_packages papirus-folders || _install_papirus_folders_upstream
        ;;
      *)
        _install_papirus_folders_upstream
        ;;
    esac
  elif ! _is_system_papirus_folders_installed; then
    local local_ver remote_ver remote_ver_num
    local_ver="$(_get_local_papirus_folders_version)"
    remote_ver="$(_fetch_remote_papirus_folders_version)"
    remote_ver_num="${remote_ver#v}"

    if [ -n "$remote_ver_num" ] && [ -n "$local_ver" ] && [ "$local_ver" != "$remote_ver_num" ]; then
      echo "Updating papirus-folders from GitHub ($local_ver -> $remote_ver)..."
      _install_papirus_folders_upstream "$remote_ver"
    else
      echo "papirus-folders is up to date (${local_ver:-latest})."
    fi
  else
    echo "papirus-folders is managed by system package manager."
  fi
}

_resolve_folder_color() {
  if [ -n "${FOLDER_COLOR:-}" ]; then
    echo "$FOLDER_COLOR"
    return 0
  fi

  local de="${1:-$(get_desktop_environment)}"
  if [ "$de" = "cinnamon" ]; then
    echo "paleorange"
  else
    echo "$DEFAULT_FOLDER_COLOR"
  fi
}

_apply_papirus_folders_color() {
  local de="${1:-$(get_desktop_environment)}"
  local color
  color="$(_resolve_folder_color "$de")"

  if ! command -v papirus-folders > /dev/null 2>&1; then
    return 0
  fi

  echo "Applying '$color' folder color via papirus-folders..."
  if [ -d "/usr/share/icons/Papirus" ] && [ ! -w "/usr/share/icons/Papirus" ] \
    && command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    sudo papirus-folders -C "$color" 2> /dev/null || true
  else
    papirus-folders -C "$color" 2> /dev/null || true
  fi
}

_configure_gnome_icon_theme() {
  echo "Configuring GNOME icon theme..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2> /dev/null || true
  fi
}

_configure_cinnamon_icon_theme() {
  echo "Configuring Cinnamon icon theme..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon.desktop.interface icon-theme "$THEME_NAME" 2> /dev/null || true
  fi
}

_configure_icon_theme() {
  local de="$1"
  case "$de" in
    gnome)
      _configure_gnome_icon_theme
      ;;
    cinnamon)
      _configure_cinnamon_icon_theme
      ;;
    *)
      return 0
      ;;
  esac
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "gnome" ] && [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (unsupported or unrecognized). Skipping icon theme setup."
    return 0
  fi

  echo "Setting up $THEME_NAME icon theme for $de..."

  _ensure_icon_theme

  _ensure_papirus_folders
  _apply_papirus_folders_color "$de"
  _configure_icon_theme "$de"

  echo "Icon theme setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
