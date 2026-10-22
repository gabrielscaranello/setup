# 🚀 Desktop Setup

Welcome! This repository automates provisioning a desktop development environment across multiple Linux distributions (Debian, Fedora, Arch Linux, openSUSE Leap & Tumbleweed).

🇧🇷 **Documentação em Português (BR):** [README-pt-br.md](README-pt-br.md)

> [!WARNING]
> This project is in early stages of development and study. It is **not yet complete** and many things **may change**. Use at your own risk.

✨ What is this
--------------

A collection of modular, idempotent bash scripts (`scripts/**/*.sh`) organized by domain to configure developer tools, runtimes, fonts, and desktop environments across multiple Linux distributions.

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

🐧 Supported Distributions & Desktops
-------------------------------------

| Distribution                 | Package Manager  | Desktop Environments | Dedicated Runner                                                |
| :--------------------------- | :--------------- | :------------------- | :-------------------------------------------------------------- |
| **Debian 13 (Trixie)**       | `apt`            | GNOME, KDE Plasma    | `runners/debian.sh` (`./main.sh debian`)                        |
| **Fedora 44**                | `dnf`            | GNOME, KDE Plasma    | `runners/fedora.sh` (`./main.sh fedora`)                        |
| **Arch Linux**               | `pacman`         | GNOME, KDE Plasma    | `runners/arch.sh` (`./main.sh arch`)                            |
| **openSUSE Leap/Tumbleweed** | `zypper`         | GNOME, KDE Plasma    | `runners/opensuse.sh` (`./main.sh opensuse`)                    |
| **WSL (Arch / Debian 13)**   | `pacman` / `apt` | CLI / WSLg           | `runners/wsl.sh` (`./main.sh wsl`) — [Setup Guide](docs/wsl.md) |

⚡ Quick start
-------------

Run full setup with automatic distribution detection, invoke specific distro pipelines, or run individual modules:

```sh
# Complete setup with auto-detection (Debian, Fedora, Arch, openSUSE Leap/Tumbleweed):
make all # Or: ./main.sh all / ./main.sh

# Explicit distribution pipelines:
./main.sh debian   # Run full Debian 13 pipeline
./main.sh fedora   # Run full Fedora 44 pipeline
./main.sh arch     # Run full Arch Linux pipeline
./main.sh opensuse # Run full openSUSE (Leap / Tumbleweed) pipeline
./main.sh wsl      # Run WSL development pipeline (CLI, Zsh, Docker, Gitflow, gh, Python, Go, NVM, Lazygit, Lazydocker, Neovim)

# Individual modules:
make neovim   # Or: ./main.sh neovim
make docker   # Or: ./main.sh docker
make firewall # Or: ./main.sh firewall

# Development, testing, and inspection:
make help             # Show all available setup commands and modules (./main.sh help)
make lint             # Run shellcheck on scripts and bats tests (yarn lint:sh & yarn lint:bats)
make format           # Format markdown and shell scripts via Prettier (yarn format)
make test             # Run all tests (e.g. DISTRO=debian FILTER=nvm)
make test-unit        # Run fast unit tests only
make test-integration # Run container integration tests only
make test-coverage    # Run tests with code coverage reports (kcov)
make clean            # Remove temporary artifacts
```

📁 Architecture & Directory Structure
------------------------------------

- `main.sh` — Master CLI entrypoint forwarder (calls `runners/main.sh`)
- `runners/` — Distro-specific setup pipelines, declarative module registry, and CLI dispatcher (`arch.sh`, `debian.sh`, `fedora.sh`, `opensuse.sh`, `main.sh`, `_modules.sh`, `_utils.sh`)
- `Makefile` — Convenience wrapper for `./main.sh`, test runners, and code quality tools
- `scripts/` — Modular setup scripts organized by domain (`apps/`, `desktop/`, `security/`, `system/`, `terminal/`, `toolchain/`, `utils/`)
- `scripts/_utils.sh` — Package manager and system helper abstractions (sourced from `scripts/utils/*.sh`)
- `scripts/packages.conf` — Cross-distro package mappings
- `docs/` — Additional guides and documentation (e.g. [WSL Installation & Provisioning Guide](docs/wsl.md))
- `openspec/` — Spec-Driven Development (SDD) capability specifications
- `tests/` — Bats unit and Docker multi-distro integration tests
- `.husky/` — Git hooks (`pre-commit` running `lint-staged`, `commit-msg` checking Conventional Commits)

🛠 Requirements
-------------

- **System Setup**: `sudo`, `git`, `bash`
- **Development & Code Quality** (optional): `node` and `yarn` (`corepack enable && yarn install` to enable Husky pre-commit hooks, Prettier, and ShellCheck)
- **Testing Suite** (optional): `docker` (to run `make test` inside isolated distro containers)

## 📖 More

- See [docs/wsl.md](docs/wsl.md) for the official WSL 3 installation guide (Arch Linux, Debian 13, `systemd`, JetBrains Mono Nerd Font, and shared `.vhdx` `ext4` persistent storage).
- See [TODO.md](TODO.md) for the project roadmap, implemented features, and planned tasks.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for the canonical script template and developer guidelines.
- See [AGENTS.md](AGENTS.md) for operational AI rules and architectural governance standards.

Made with ❤️ — happy hacking!
