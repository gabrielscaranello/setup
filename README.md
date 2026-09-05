# 🚀 Desktop Setup

Welcome! This repository automates provisioning a desktop development environment across multiple Linux distributions (Debian, Fedora, Arch Linux).

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

⚡ Quick start
-------------

Run full setup or inspect available module commands:

```sh
make help              # Show all available setup commands and modules (./main.sh help)
make all               # Run full desktop setup (./main.sh)
make <module>          # Run a specific module (e.g. make neovim, make docker, make firewall)
make test              # Run all tests (e.g. DISTRO=debian FILTER=nvm)
make test-unit         # Run fast unit tests only
make test-integration  # Run container integration tests only
make test-coverage     # Run tests with code coverage reports (kcov)
make clean             # Remove temporary artifacts
```

📁 Architecture & Directory Structure
------------------------------------

- `main.sh` — Master CLI entrypoint forwarder (calls `runners/main.sh`)
- `runners/` — Distro-specific setup pipelines and CLI dispatcher (`arch.sh`, `debian.sh`, `fedora.sh`, `main.sh`, `_utils.sh`)
- `Makefile` — Convenience wrapper for `./main.sh` and test runners
- `scripts/` — Modular setup scripts organized by domain (`apps/`, `security/`, `system/`, `terminal/`, `toolchain/`)
- `scripts/_utils.sh` — Package manager and system helper abstractions
- `scripts/packages.conf` — Cross-distro package mappings
- `openspec/` — Spec-Driven Development (SDD) capability specifications
- `tests/` — Bats unit and Docker multi-distro integration tests

🛠 Requirements
-------------

- **System Setup**: `sudo`, `git`, `bash`
- **Testing Suite** (optional): `docker` (to run `make test` inside isolated distro containers)

## 📖 More

- See [TODO.md](TODO.md) for the project roadmap, implemented features, and planned tasks.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for the canonical script template and developer guidelines.
- See [AGENTS.md](AGENTS.md) for operational AI rules and architectural governance standards.

Made with ❤️ — happy hacking!

