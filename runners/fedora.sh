#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

run_all() {
  local steps=(
    "setup-swap.sh:Swap and memory tuning setup"
    "setup-timeshift.sh:Timeshift setup"
    "setup-docker.sh:Docker setup"
    "setup-flatpak.sh:Flatpak setup"
    "setup-firewall.sh:Firewall setup"
    "setup-browsers.sh:Browsers setup"
    "setup-dbeaver.sh:DBeaver setup"
    "setup-discord.sh:Discord setup"
    "setup-telegram.sh:Telegram setup"
    "setup-fonts.sh:Fonts setup"
    "setup-gitflow.sh:Gitflow setup"
    "setup-go.sh:Golang setup"
    "setup-nvm.sh:NVM/Node setup"
    "setup-kitty.sh:Kitty terminal setup"
    "setup-lazygit.sh:Lazygit setup"
    "setup-lazydocker.sh:Lazydocker setup"
    "setup-neovim.sh:Neovim setup"
    "setup-default-apps.sh:Default applications setup"
  )

  run_pipeline "Fedora Desktop Setup" "${steps[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
