#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/_utils.sh" 2> /dev/null || true

WSL_STEPS=(
  "system/setup-update.sh:System packages and repositories update"
  "terminal/setup-cli.sh:CLI utilities, Zsh and clipboard setup"
  "toolchain/setup-gitflow.sh:Gitflow setup"
  "toolchain/setup-gh.sh:GitHub CLI (gh) setup"
  "toolchain/setup-python.sh:Python, pip and venv setup"
  "toolchain/setup-go.sh:Golang setup"
  "toolchain/setup-rust.sh:Rust, Cargo and tree-sitter-cli setup"
  "toolchain/setup-nvm.sh:NVM, Node.js and global npm packages setup"
  "terminal/setup-lazygit.sh:Lazygit setup"
  "terminal/setup-lazydocker.sh:Lazydocker setup"
  "toolchain/setup-neovim.sh:Neovim and runtime dependencies setup"
)

run_all() {
  require_supported_distro > /dev/null || return 1
  run_pipeline "WSL Development Setup" "${WSL_STEPS[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all "$@"
fi
