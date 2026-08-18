# 🤖 AI Agent Guidelines & Context — Desktop Setup

This file is the authoritative source of truth for AI assistants, coding agents, and maintainers regarding repository architecture, conventions, quality standards, and mandatory documentation rules.

---

## 📌 Project Overview

This repository provides automated, modular, and idempotent bash setup scripts for configuring a Linux desktop development environment across supported distributions:

- **Debian** (`apt`)
- **Fedora** (`dnf`)
- **Arch Linux** (`pacman`)

---

## 📁 Repository Architecture & Layout

- **[main.sh](main.sh)**: Master orchestrator script that runs the full installation flow.
- **[Makefile](Makefile)**: User-facing runner (`make help`, `make all`, `make neovim`, `make nvm`, `make terminal`, `make clean`).
- **[scripts/\_utils.sh](scripts/_utils.sh)**: Core abstraction for package management (`_get_package_manager`, `_install_packages`, `_get_package_name`).
- **[scripts/setup-neovim.sh](scripts/setup-neovim.sh)**: Builds/installs Neovim (from source with DEB packaging on Debian; native packages on Arch/Fedora). Ensures NVM is installed as a prerequisite.
- **[scripts/setup-nvm.sh](scripts/setup-nvm.sh)**: Installs NVM (via upstream install script on Debian/Fedora; native package on Arch), Node.js v24, Corepack, and global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`, `yarn`).
- **[scripts/setup-terminal.sh](scripts/setup-terminal.sh)**: Terminal customization script (WIP).

---

## 📜 Script Development Conventions

All scripts under `scripts/*.sh` must adhere to the standard pattern:

1. **Strict mode**: Begin with `set -euo pipefail` (or `set -e`).
2. **Import helpers**: Include `source "$(dirname "$0")/_utils.sh"` near the top.
3. **Encapsulation**: Prefix private functions with an underscore `_` (e.g. `_install_packages`).
4. **Entrypoint**: Implement a `main()` function and invoke it at the end with `main "$@"`.
5. **Cross-Distro**: Use `_get_package_manager` and `_utils.sh` mappings instead of hardcoded package managers.
6. **Idempotence**: Scripts must be safe to rerun multiple times without side effects.
7. **Temporary Builds**: Use `/tmp/<package>` and ensure `make clean` removes generated artifacts.

---

## 🚫 AI Operational Rules & Commit Policy

- **No Automated Commits**: AI assistants and agents must **NEVER** execute `git commit`, `git push`, or alter git history directly.
- **Developer Ownership**: All commits must be made exclusively by the human developer after reviewing and validating the changes.

---

## 📋 Mandatory Documentation Rules

Whenever a new script is added or an existing script/flow is modified under `scripts/`, `main.sh`, or `Makefile`:

1. **[Makefile](Makefile)**: Add the target with help documentation. Targets must be ordered alphabetically with `help` and `all` at the top and `clean` at the bottom.
2. **[README.md](README.md)**: Update the "Quick start" section maintaining the same alphabetical target order.
3. **[README-pt-br.md](README-pt-br.md)**: Update the "Como usar (rápido)" section matching the English README.
4. **[AGENTS.md](AGENTS.md)**: Update reference notes and architecture overview if orchestration or public behavior changed.

---

## 🛠️ Validation & Commands

- **Run full setup**: `make all` (or `./main.sh`)
- **Run individual targets**: `make neovim`, `make nvm`, `make terminal`
- **Clean build artifacts**: `make clean`
- **Show available targets**: `make help`
- **Lint / Validate syntax**: `shellcheck -x scripts/*.sh`

---

## 📖 Deep-Dive References

- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Developer contribution guidelines, PR checklist, and code style.
- **[README.md](README.md)**: Canonical user-facing documentation and quick start.
- **[README-pt-br.md](README-pt-br.md)**: Documentação em português.
