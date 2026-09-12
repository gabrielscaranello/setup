#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_favorite_apps.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_plasma.sh" 2> /dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config/gnome"

GNOME_DCONF_FILES=(
  "interface.dconf"
  "peripherals.dconf"
  "window-manager.dconf"
  "night-light.dconf"
  "privacy.dconf"
  "nautilus.dconf"
  "shell.dconf"
  "apps.dconf"
)

_setup_gnome_workspace_env() {
  local config_dir="$HOME/.config"
  local env_dir="${config_dir}/gnome/env"
  local autostart_dir="${config_dir}/autostart"
  local generators_dir="${config_dir}/systemd/user-environment-generators"
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local template_env="${GNOME_WORKSPACE_ENV_NVM:-${repo_root}/config/gnome/env/nvm.sh}"
  local template_desktop="${GNOME_AUTOSTART_NVM:-${repo_root}/config/gnome/autostart/nvm-env.desktop}"

  if [ -f "$template_env" ]; then
    echo "Configuring GNOME workspace startup environment script for NVM..."
    mkdir -p "$env_dir" "$autostart_dir" "$generators_dir"
    cp "$template_env" "${env_dir}/nvm.sh"
    chmod +x "${env_dir}/nvm.sh"

    if [ -f "$template_desktop" ]; then
      cp "$template_desktop" "${autostart_dir}/nvm-env.desktop"
    fi

    # Systemd user environment generator for early session PATH injection
    cat << 'EOF' > "${generators_dir}/10-nvm.sh"
#!/bin/sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" > /dev/null 2>&1
[ -f /usr/share/nvm/init-nvm.sh ] && . /usr/share/nvm/init-nvm.sh > /dev/null 2>&1

if [ -n "${NVM_BIN:-}" ]; then
  echo "NVM_DIR=$NVM_DIR"
  echo "NVM_BIN=$NVM_BIN"
  echo "PATH=$NVM_BIN:$PATH"
fi
EOF
    chmod +x "${generators_dir}/10-nvm.sh"
  fi
}

main() {
  set -euo pipefail
  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Starting GNOME desktop preferences configuration..."
      ensure_dconf || return 1
      echo "Applying GNOME desktop environment preferences..."
      load_dconf_files "$CONFIG_DIR" "${GNOME_DCONF_FILES[@]}" || return 1
      configure_gnome_favorite_apps
      _setup_gnome_workspace_env
      echo "GNOME desktop preferences configuration completed successfully."
      ;;
    plasma)
      echo "Starting KDE Plasma 6 desktop preferences configuration..."
      configure_plasma_preferences || return 1
      echo "KDE Plasma 6 desktop preferences configuration completed successfully."
      ;;
    *)
      echo "Desktop Environment is '$de' (unsupported desktop environment). Skipping desktop preferences configuration."
      return 0
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
