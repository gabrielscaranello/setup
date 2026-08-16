# 🚀 Desktop Setup

Welcome! This repository automates provisioning a desktop development environment across multiple Linux distributions (Ubuntu/Debian, Fedora/RHEL, openSUSE, Arch).

✨ What is this
--------------

A collection of idempotent scripts (scripts/*.sh) to install and configure developer tools such as Neovim and terminal enhancements.

🎯 Goals
-------

- Automate desktop dev environment setup across distros.
- Keep scripts generic and idempotent with a package-manager shim.
- Make scripts modular and testable for reuse.

⚡ Quick start
-------------

Run Makefile targets:

```sh
make help     # Show available targets
make all      # Run full setup (./main.sh)
make neovim   # Neovim only
make nvm      # NVM/Node only
make terminal # Terminal tweaks
make clean    # Remove temporary artifacts
```

📁 Layout
-------

- main.sh — Orchestrator
- Makefile — Convenience runner
- scripts/_utils.sh — Package-manager abstraction
- scripts/setup-neovim.sh — Build/install Neovim
- scripts/setup-terminal.sh — Terminal tweaks (WIP)

🛠 Requirements
-------------

- sudo
- git
- bash

## 📖 More

See [CONTRIBUTING.md](CONTRIBUTING.md) for the canonical script template and developer guidelines.

Made with ❤️ — happy hacking!
