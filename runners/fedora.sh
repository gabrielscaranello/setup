#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

run_all() {
  local steps=(
    "system/setup-swap.sh:Swap and memory tuning setup"
    "system/setup-timeshift.sh:Timeshift setup"
    "toolchain/setup-docker.sh:Docker setup"
    "system/setup-flatpak.sh:Flatpak setup"
    "security/setup-firewall.sh:Firewall setup"
    "apps/setup-browsers.sh:Browsers setup"
    "apps/setup-dbeaver.sh:DBeaver setup"
    "apps/setup-discord.sh:Discord setup"
    "apps/setup-telegram.sh:Telegram setup"
    "apps/setup-vscodium.sh:VSCodium setup"
    "terminal/setup-fonts.sh:Fonts setup"
    "toolchain/setup-gitflow.sh:Gitflow setup"
    "toolchain/setup-go.sh:Golang setup"
    "toolchain/setup-nvm.sh:NVM/Node setup"
    "terminal/setup-kitty.sh:Kitty terminal setup"
    "terminal/setup-lazygit.sh:Lazygit setup"
    "terminal/setup-lazydocker.sh:Lazydocker setup"
    "toolchain/setup-neovim.sh:Neovim setup"
    "apps/setup-default-apps.sh:Default applications setup"
  )

  run_pipeline "Fedora Desktop Setup" "${steps[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
