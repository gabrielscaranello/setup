# 🚀 Desktop Setup

Welcome! This repository automates provisioning a desktop development environment across multiple Linux distributions (Debian, Fedora, Arch Linux).

🇧🇷 **Documentação em Português (BR):** [README-pt-br.md](README-pt-br.md)

> [!WARNING]
> This project is in early stages of development and study. It is **not yet complete** and many things **may change**. Use at your own risk.

✨ What is this
--------------

A collection of modular, idempotent bash scripts (`scripts/*.sh`) to configure developer tools, runtimes, fonts, and desktop environments across multiple Linux distributions.

💡 Motivation & Context
-----------------------

This project was created to unify and centralize several standalone distribution setup repositories into a single, maintainable codebase to streamline my daily [distro-hopping](https://en.wiktionary.org/wiki/distro-hopping) workflow (the practice of frequently switching and testing different Linux distributions):

- 🌀 [gabrielscaranello/debian](https://github.com/gabrielscaranello/debian)
- 🌿 [gabrielscaranello/mint-setup](https://github.com/gabrielscaranello/mint-setup)
- 🎩 [gabrielscaranello/fedora-setup](https://github.com/gabrielscaranello/fedora-setup)
- 🐧 [gabrielscaranello/arch-setup](https://github.com/gabrielscaranello/arch-setup)
- 🔷 [gabrielscaranello/zorin-setup](https://github.com/gabrielscaranello/zorin-setup)
- 🦎 [gabrielscaranello/opensuse](https://github.com/gabrielscaranello/opensuse)

---

> [!NOTE]
> **Personal Setup vs. General Utilities**: This repository is tailored specifically to my personal workflow, preferred software stack, and opinions. It is shared openly with the community in case it serves as inspiration or a reference for building modular multi-distro scripts.
>
> If you are looking for a comprehensive, general-purpose post-install Linux utility for the broader community, check out [Linux Toys](https://github.com/psygreg/linuxtoys).
>
> User configuration and dotfiles are maintained separately in [gabrielscaranello/dotfiles](https://github.com/gabrielscaranello/dotfiles) (with potential future integration planned here).

🎯 Goals
-------

- Centralize and automate desktop dev environment setup across distros.
- Keep scripts generic and idempotent with a package-manager shim.
- Make scripts modular and testable for reuse.

⚡ Quick start
-------------

Run Makefile targets:

```sh
make help              # Show available targets
make all               # Run full setup (./main.sh)
make browsers          # Browsers only (Chromium, Firefox)
make dbeaver           # DBeaver only
make default-apps      # Default applications only (Kitty terminal, MIME)
make discord           # Discord only
make docker            # Docker only
make firewall          # Firewall and GUI frontend only
make flatpak           # Flatpak and Flathub only
make fonts             # JetBrains Mono Nerd Font only
make gitflow           # Gitflow CJS only
make go                # Golang only
make kernel-debian     # Debian backports kernel and headers only
make kitty             # Kitty terminal emulator only
make lazydocker        # Lazydocker only
make lazygit           # Lazygit only
make neovim            # Neovim only
make nvm               # NVM/Node only
make rust              # Rust/Cargo only
make swap              # Swap and VM tuning only
make telegram          # Telegram Desktop only
make timeshift         # Timeshift only
make test              # Run all tests (e.g. DISTRO=debian FILTER=nvm)
make test-coverage     # Run tests with code coverage reports (kcov)
make test-integration  # Run container integration tests only
make test-unit         # Run fast unit tests only
make clean             # Remove temporary artifacts
```

📁 Layout
-------

- main.sh — Orchestrator
- Makefile — Convenience runner
- scripts/_utils.sh — Package-manager abstraction
- scripts/debian/_repositories.sh — Debian repository helper functions
- scripts/debian/setup-kernel.sh — Install latest Linux kernel and headers from Debian backports
- scripts/setup-browsers.sh — Install Browsers (Chromium, Firefox)
- scripts/setup-dbeaver.sh — Install DBeaver
- scripts/setup-default-apps.sh — Configure default desktop applications (Kitty terminal, MIME)
- scripts/setup-discord.sh — Install Discord
- scripts/setup-docker.sh — Install Docker and plugins
- scripts/setup-firewall.sh — Configure Firewall (firewalld on Fedora, UFW on Debian/Arch) and GUI
- scripts/setup-flatpak.sh — Configure Flatpak and Flathub repository
- scripts/setup-fonts.sh — Install JetBrains Mono Nerd Font
- scripts/setup-gitflow.sh — Install Gitflow CJS
- scripts/setup-go.sh — Install Golang
- scripts/setup-kitty.sh — Install Kitty terminal emulator
- scripts/setup-lazydocker.sh — Install Lazydocker
- scripts/setup-lazygit.sh — Install Lazygit
- scripts/setup-neovim.sh — Build/install Neovim
- scripts/setup-nvm.sh — Install NVM, Node.js and global packages
- scripts/setup-rust.sh — Install Rust, Cargo and tools (tree-sitter-cli)
- scripts/setup-swap.sh — Configure Swap and VM memory tuning
- scripts/setup-telegram.sh — Install Telegram Desktop
- scripts/setup-timeshift.sh — Install and configure Timeshift

🛠 Requirements
-------------

- sudo
- git
- bash

## 📖 More

- See [TODO.md](TODO.md) for the project roadmap, implemented features, and planned tasks.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for the canonical script template and developer guidelines.

Made with ❤️ — happy hacking!
