#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_theme_utils.sh" 2> /dev/null || true

THEME_NAME="Papirus-Dark"
DEFAULT_FOLDER_COLOR="adwaita"
FOLDER_COLOR="${FOLDER_COLOR:-$DEFAULT_FOLDER_COLOR}"
FOLDERS_UPSTREAM_REPO="PapirusDevelopmentTeam/papirus-folders"
CATPPUCCIN_UPSTREAM_REPO="catppuccin/papirus-folders"
ICON_UPSTREAM_REPO="PapirusDevelopmentTeam/papirus-icon-theme"

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
  local tmp_script="/tmp/papirus-folders_$$"

  download_file "$script_url" "$tmp_script"
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

  rm -f "$tmp_script"
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

_get_papirus_icons_dir() {
  local dir
  for dir in "/usr/share/icons/Papirus" "$HOME/.local/share/icons/Papirus" "$HOME/.icons/Papirus"; do
    if [ -d "$dir" ]; then
      echo "$dir"
      return 0
    fi
  done
  echo "/usr/share/icons/Papirus"
}

_is_catppuccin_folders_installed() {
  local papirus_dir
  papirus_dir="$(_get_papirus_icons_dir)"
  [ -f "$papirus_dir/48x48/places/folder-cat-mocha-lavender-documents.svg" ]
}

_install_catppuccin_papirus_folders() {
  local papirus_dir
  papirus_dir="$(_get_papirus_icons_dir)"

  echo "Installing Catppuccin Papirus folder colors..."
  local tmp_dir="/tmp/catppuccin_papirus_$$"
  local archive_url="https://github.com/${CATPPUCCIN_UPSTREAM_REPO}/archive/refs/heads/main.tar.gz"
  local archive_path="/tmp/catppuccin_papirus_$$.tar.gz"

  rm -rf "$tmp_dir" "$archive_path"
  mkdir -p "$tmp_dir"

  download_file "$archive_url" "$archive_path" || {
    echo "Warning: Failed to download Catppuccin Papirus folders archive."
    rm -rf "$tmp_dir" "$archive_path"
    return 1
  }

  tar -xzf "$archive_path" -C "$tmp_dir" || {
    rm -rf "$tmp_dir" "$archive_path"
    return 1
  }

  local src_dir="$tmp_dir/papirus-folders-main/src"
  if [ -d "$src_dir" ]; then
    if [ -w "$papirus_dir" ]; then
      cp -r "$src_dir"/* "$papirus_dir/"
    elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
      sudo cp -r "$src_dir"/* "$papirus_dir/"
    else
      local user_papirus_dir="$HOME/.local/share/icons/Papirus"
      mkdir -p "$user_papirus_dir"
      if [ -d "/usr/share/icons/Papirus" ] && [ ! -d "$user_papirus_dir/48x48" ]; then
        cp -rn /usr/share/icons/Papirus/* "$user_papirus_dir/" 2> /dev/null || true
      fi
      cp -r "$src_dir"/* "$user_papirus_dir/"
    fi
  fi

  rm -rf "$tmp_dir" "$archive_path"
}

_apply_papirus_folders_color() {
  if ! command -v papirus-folders > /dev/null 2>&1; then
    return 0
  fi

  if [[ "$FOLDER_COLOR" == cat-* ]] && ! _is_catppuccin_folders_installed; then
    _install_catppuccin_papirus_folders || true
  fi

  echo "Applying '$FOLDER_COLOR' folder color via papirus-folders..."
  if [ -d "/usr/share/icons/Papirus" ] && [ ! -w "/usr/share/icons/Papirus" ] \
    && command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    sudo papirus-folders -C "$FOLDER_COLOR" 2> /dev/null || true
  else
    papirus-folders -C "$FOLDER_COLOR" 2> /dev/null || true
  fi
}

_configure_gnome_icon_theme() {
  echo "Configuring GNOME icon theme..."
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2> /dev/null || true
  fi
}

_configure_cinnamon_icon_theme() {
  echo "Configuring Cinnamon icon theme..."
  if command -v dconf > /dev/null 2>&1; then
    dconf write /org/cinnamon/desktop/interface/icon-theme "'$THEME_NAME'" 2> /dev/null || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings set org.cinnamon.desktop.interface icon-theme "$THEME_NAME" 2> /dev/null || true
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

  if [ "$FOLDER_COLOR" = "$DEFAULT_FOLDER_COLOR" ] && [ "$de" = "cinnamon" ]; then
    FOLDER_COLOR="cat-mocha-lavender"
  fi

  echo "Setting up $THEME_NAME icon theme for $de..."

  _ensure_icon_theme

  _ensure_papirus_folders
  _apply_papirus_folders_color
  _configure_icon_theme "$de"

  echo "Icon theme setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
