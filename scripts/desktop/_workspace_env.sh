#!/bin/bash

# Desktop Workspace Environment & Session Initialization
# Configures NVM and early session PATH injection for GNOME and KDE Plasma.

_setup_gnome_workspace_env() {
  local config_dir="$HOME/.config"
  local env_dir="${config_dir}/gnome/env"
  local autostart_dir="${config_dir}/autostart"
  local generators_dir="${config_dir}/systemd/user-environment-generators"
  local repo_root
  repo_root="$(get_repo_root)"
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

_setup_plasma_workspace_env() {
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local env_dir="${config_dir}/plasma-workspace/env"
  local target_file="${env_dir}/nvm.sh"
  local repo_root
  repo_root="$(get_repo_root)"
  local template_file="${PLASMA_WORKSPACE_ENV_NVM:-${repo_root}/config/plasma/plasma-workspace/env/nvm.sh}"

  if [ -f "$template_file" ]; then
    echo "Configuring KDE Plasma workspace startup environment script for NVM..."
    mkdir -p "$env_dir"
    cp "$template_file" "$target_file"
    chmod +x "$target_file"
  fi
}
