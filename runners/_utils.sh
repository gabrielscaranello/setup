#!/bin/bash
set -euo pipefail

run_pipeline() {
  local pipeline_name="$1"
  shift
  local steps=("$@")
  local scripts_dir
  scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

  echo "======================================="
  echo "   $pipeline_name Pipeline"
  echo "======================================="
  echo ""

  local step_file step_desc
  for step in "${steps[@]}"; do
    step_file="${step%%:*}"
    step_desc="${step##*:}"
    echo ">>> Running $step_desc..."
    echo ""
    bash "$scripts_dir/$step_file"
    echo ""
    echo "✓ $step_desc completed"
    echo ""
  done

  echo "======================================="
  echo "   $pipeline_name Setup Completed Successfully!"
  echo "======================================="
}

COMMON_INITIAL_STEPS=(
  "system/setup-swap.sh:Swap and memory tuning setup"
  "system/setup-packages.sh:Core system packages setup"
)

COMMON_POST_STEPS=(
  "system/setup-nvidia.sh:NVIDIA graphics drivers setup"
  "system/setup-amd.sh:AMD graphics drivers and codecs setup"
  "system/setup-codecs.sh:Multimedia codecs and A/V plugins setup"
  "toolchain/setup-docker.sh:Docker setup"
  "system/setup-flatpak.sh:Flatpak setup"
  "security/setup-firewall.sh:Firewall setup"
  "apps/setup-browsers.sh:Browsers setup"
  "apps/setup-dbeaver.sh:DBeaver setup"
  "apps/setup-gimp.sh:GIMP setup"
  "apps/setup-onlyoffice.sh:ONLYOFFICE setup"
  "apps/setup-obsidian.sh:Obsidian setup"
  "apps/setup-mongodb-compass.sh:MongoDB Compass setup"
  "apps/setup-screenshot-tool.sh:Screenshot tool setup"
  "apps/setup-discord.sh:Discord setup"
  "apps/setup-telegram.sh:Telegram setup"
  "apps/setup-vscodium.sh:VSCodium setup"
  "apps/setup-steam.sh:Steam and gaming tools setup"
  "terminal/setup-fonts.sh:Fonts setup"
  "toolchain/setup-gitflow.sh:Gitflow setup"
  "toolchain/setup-go.sh:Golang setup"
  "toolchain/setup-nvm.sh:NVM/Node setup"
  "terminal/setup-kitty.sh:Kitty terminal setup"
  "terminal/setup-lazygit.sh:Lazygit setup"
  "terminal/setup-lazydocker.sh:Lazydocker setup"
  "toolchain/setup-neovim.sh:Neovim setup"
  "apps/setup-default-apps.sh:Default applications setup"
  "desktop/setup-desktop-apps.sh:Desktop environment applications setup"
  "desktop/setup-cursor-theme.sh:Cursor theme setup"
  "desktop/setup-gtk-theme.sh:GTK theme setup"
  "desktop/setup-icon-theme.sh:Icon theme setup"
  "desktop/setup-gnome-extensions.sh:GNOME extensions setup"
  "desktop/setup-gnome-extensions-config.sh:GNOME extensions configuration"
  "desktop/setup-desktop-preferences.sh:Desktop environment preferences"
  "desktop/setup-hide-apps.sh:Hide unwanted desktop applications"
)
