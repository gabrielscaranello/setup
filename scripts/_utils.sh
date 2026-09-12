#!/bin/bash

get_distro_id() {
  local os_release_file="${OS_RELEASE_PATH:-/etc/os-release}"
  if [ ! -f "$os_release_file" ] && [ -f /usr/lib/os-release ]; then
    os_release_file="/usr/lib/os-release"
  fi

  if [ -f "$os_release_file" ]; then
    local distro_id
    distro_id="$(grep '^ID=' "$os_release_file" 2> /dev/null | head -n 1 | cut -d= -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]' || true)"
    if [ -n "$distro_id" ]; then
      echo "$distro_id"
      return 0
    fi
  fi

  if command -v lsb_release > /dev/null 2>&1; then
    local lsb_id
    lsb_id="$(lsb_release -si 2> /dev/null | tr '[:upper:]' '[:lower:]' || true)"
    if [ -n "$lsb_id" ]; then
      echo "$lsb_id"
      return 0
    fi
  fi

  echo "unknown"
  return 1
}

is_distro() {
  local target="$1"
  local current
  current="$(get_distro_id 2> /dev/null || echo "unknown")"
  [ "$current" = "$target" ]
}

_get_package_manager() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  case "$distro" in
    debian)
      echo "apt"
      return 0
      ;;
    fedora)
      echo "dnf"
      return 0
      ;;
    arch)
      echo "pacman"
      return 0
      ;;
  esac

  if command -v dnf > /dev/null 2>&1; then
    echo "dnf"
  elif command -v apt > /dev/null 2>&1; then
    echo "apt"
  elif command -v pacman > /dev/null 2>&1; then
    echo "pacman"
  else
    return 1
  fi
}

_get_package_name() {
  local package="$1"
  local target="${2:-}"
  if [ -z "$target" ]; then
    target="$(get_distro_id 2> /dev/null || _get_package_manager 2> /dev/null || true)"
  fi
  local config_file=""

  if [ -f "scripts/packages.conf" ]; then
    config_file="scripts/packages.conf"
  elif [ -f "$(dirname "${BASH_SOURCE[0]}")/packages.conf" ]; then
    config_file="$(dirname "${BASH_SOURCE[0]}")/packages.conf"
  elif [ -f "/setup/scripts/packages.conf" ]; then
    config_file="/setup/scripts/packages.conf"
  fi

  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    local field_idx=0
    case "$target" in
      debian | apt) field_idx=2 ;;
      fedora | dnf) field_idx=3 ;;
      arch | pacman) field_idx=4 ;;
      *) field_idx=0 ;;
    esac

    if [ "$field_idx" -gt 0 ]; then
      local matched_line
      matched_line="$(awk -F' *\\| *' -v pkg="$package" '$1 == pkg { print $0; exit }' "$config_file" 2> /dev/null || true)"
      if [ -n "$matched_line" ]; then
        local resolved_pkg
        resolved_pkg="$(echo "$matched_line" | awk -F' *\\| *' -v col="$field_idx" '{ print $col }')"
        if [ "$resolved_pkg" = "-" ]; then
          echo ""
        else
          echo "$resolved_pkg"
        fi
        return 0
      fi
    fi
  fi

  echo "$package"
}

_install_package_from_repository() {
  local package_manager="$1"
  shift

  case "$package_manager" in
    apt)
      sudo apt update -qq
      sudo apt install -y "$@"
      ;;

    dnf)
      sudo dnf install -y --allowerasing "$@"
      ;;

    pacman)
      sudo pacman -Sy --needed --noconfirm "$@"
      ;;

    *)
      echo "Unsupported package manager: $package_manager" >&2
      return 1
      ;;
  esac
}

install_packages() {
  local package_manager distro
  distro="$(get_distro_id 2> /dev/null || echo "unknown")"
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  echo "Using package manager: $package_manager (distribution: $distro)"

  local resolved_packages=()
  local package
  local resolved
  for package in "$@"; do
    resolved="$(_get_package_name "$package" "$distro")"
    if [ -n "$resolved" ]; then
      for item in $resolved; do
        resolved_packages+=("$item")
      done
    fi
  done

  if [ ${#resolved_packages[@]} -eq 0 ]; then
    echo "No packages to install for $package_manager"
    return 0
  fi

  echo "Installing: ${resolved_packages[*]}"

  _install_package_from_repository "$package_manager" "${resolved_packages[@]}"
}

get_root_filesystem() {
  findmnt -n -o FSTYPE / 2> /dev/null || df -T / 2> /dev/null | awk 'NR==2 {print $2}' || echo "unknown"
}

get_gpu_vendor() {
  if [ -n "${GPU_VENDOR:-}" ]; then
    echo "$GPU_VENDOR"
    return 0
  fi

  if command -v lspci > /dev/null 2>&1; then
    local pci_display
    pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
    if [ -n "$pci_display" ]; then
      if echo "$pci_display" | grep -iq "10de" || echo "$pci_display" | grep -iq "nvidia"; then
        echo "nvidia"
        return 0
      elif echo "$pci_display" | grep -iq "1002" || echo "$pci_display" | grep -iqE "amd|advanced micro devices|radeon"; then
        echo "amd"
        return 0
      elif echo "$pci_display" | grep -iq "8086" || echo "$pci_display" | grep -iq "intel"; then
        echo "intel"
        return 0
      fi
    fi
  fi

  echo "unknown"
}

get_desktop_environment() {
  local de="${TARGET_DE:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}"
  if [ -z "$de" ] && [ -f "$HOME/.config/setup/desktop-environment" ]; then
    de="$(cat "$HOME/.config/setup/desktop-environment" 2> /dev/null || true)"
  fi
  de="$(echo "$de" | tr '[:upper:]' '[:lower:]')"

  case "$de" in
    *gnome*) echo "gnome" ;;
    *kde* | *plasma*) echo "plasma" ;;
    *) echo "unknown" ;;
  esac
}

save_desktop_environment() {
  local de="$1"
  export TARGET_DE="$de"
  mkdir -p "$HOME/.config/setup" 2> /dev/null || true
  echo "$de" > "$HOME/.config/setup/desktop-environment" 2> /dev/null || true
}

prompt_desktop_environment() {
  local prompt_label="${1:-Selecione o Desktop Environment:}"
  local default_de="${2:-plasma}"

  if [ -t 0 ]; then
    echo "" >&2
    echo "Nenhum ambiente gráfico ativo detectado." >&2
    echo "$prompt_label" >&2
    echo "  1) KDE Plasma (Recomendado)" >&2
    echo "  2) GNOME" >&2
    echo "" >&2
    local choice=""
    read -r -p "Opção [1-2, padrão: 1]: " choice || true
    case "$choice" in
      2 | [gG]*) echo "gnome" ;;
      *) echo "plasma" ;;
    esac
  else
    echo "$default_de"
  fi
}

ensure_desktop_environment() {
  local prompt_label="${1:-Selecione o Desktop Environment:}"
  local de
  de="$(get_desktop_environment)"

  if [ "$de" = "unknown" ]; then
    de="$(prompt_desktop_environment "$prompt_label")"
  fi

  save_desktop_environment "$de"
  echo "$de"
}

get_shell_profile() {
  case "${SHELL##*/}" in
    zsh) echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

install_flatpak_app() {
  local app_id="$1"
  local app_name="${2:-$app_id}"
  local script_dir

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/system/setup-flatpak.sh" ]; then
    bash "$script_dir/system/setup-flatpak.sh"
  elif [ -f "$script_dir/setup-flatpak.sh" ]; then
    bash "$script_dir/setup-flatpak.sh"
  elif [ -f "$script_dir/../setup-flatpak.sh" ]; then
    bash "$script_dir/../setup-flatpak.sh"
  fi

  if flatpak list --app --columns=application 2> /dev/null | grep -qx "$app_id"; then
    echo "$app_name (Flatpak) is already installed, skipping."
    return 0
  fi

  echo "Installing $app_name via Flatpak (Flathub)..."
  sudo flatpak install -y --noninteractive flathub "$app_id"
  echo "$app_name Flatpak installed successfully."
}

download_file() {
  local url="$1"
  local dest="$2"

  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget > /dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Error: Neither curl nor wget is available to download $url" >&2
    return 1
  fi
}

fetch_url() {
  local url="$1"

  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" 2> /dev/null || true
  elif command -v wget > /dev/null 2>&1; then
    wget -qO- "$url" 2> /dev/null || true
  fi
}

# shellcheck disable=SC2016
ensure_xdg_terminal_exec() {
  local user_bin="$HOME/.local/bin"
  mkdir -p "$user_bin"

  local script_content='#!/bin/sh
if [ "${1:-}" = "-e" ] || [ "${1:-}" = "--" ]; then
  shift
fi

if command -v kitty > /dev/null 2>&1; then
  TERMINAL="kitty"
elif [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
  TERMINAL="$HOME/.local/kitty.app/bin/kitty"
elif [ -x "$HOME/.local/bin/kitty" ]; then
  TERMINAL="$HOME/.local/bin/kitty"
else
  TERMINAL="kitty"
fi

if [ "$#" -eq 0 ]; then
  exec "$TERMINAL"
else
  exec "$TERMINAL" "$@"
fi'

  echo "$script_content" > "$user_bin/xdg-terminal-exec"
  chmod 755 "$user_bin/xdg-terminal-exec"
  ln -sf "xdg-terminal-exec" "$user_bin/x-terminal-emulator"
  if [ ! -f "/usr/bin/gnome-terminal" ]; then
    ln -sf "xdg-terminal-exec" "$user_bin/gnome-terminal"
  fi

  if [ -w "/usr/local/bin" ]; then
    echo "$script_content" > "/usr/local/bin/xdg-terminal-exec"
    chmod 755 "/usr/local/bin/xdg-terminal-exec"
    ln -sf "xdg-terminal-exec" "/usr/local/bin/x-terminal-emulator"
    if [ ! -f "/usr/bin/gnome-terminal" ]; then
      ln -sf "xdg-terminal-exec" "/usr/local/bin/gnome-terminal"
    fi
  elif command -v sudo > /dev/null 2>&1; then
    local tmp_script
    tmp_script="$(mktemp)"
    echo "$script_content" > "$tmp_script"
    chmod 755 "$tmp_script"
    sudo cp "$tmp_script" "/usr/local/bin/xdg-terminal-exec" 2> /dev/null || true
    sudo chmod 755 "/usr/local/bin/xdg-terminal-exec" 2> /dev/null || true
    sudo ln -sf "/usr/local/bin/xdg-terminal-exec" "/usr/local/bin/x-terminal-emulator" 2> /dev/null || true
    if [ ! -f "/usr/bin/gnome-terminal" ]; then
      sudo ln -sf "/usr/local/bin/xdg-terminal-exec" "/usr/local/bin/gnome-terminal" 2> /dev/null || true
    fi
    rm -f "$tmp_script"
  fi

  local env_d="$HOME/.config/environment.d"
  mkdir -p "$env_d"
  if [ ! -f "$env_d/10-local-path.conf" ]; then
    echo 'PATH="${HOME}/.local/bin:${PATH}"' > "$env_d/10-local-path.conf"
  fi
}
