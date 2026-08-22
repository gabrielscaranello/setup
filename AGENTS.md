# 🤖 AI Agent Guidelines & Context — Desktop Setup

This file is the authoritative source of truth for AI assistants, coding agents, and maintainers regarding operational rules, AI constraints, and mandatory synchronization policies.

For script conventions, repository layout, developer contribution guides, and integration test specifications, refer directly to:
👉 **[CONTRIBUTING.md](CONTRIBUTING.md)**

---

## 📌 Project Overview

This repository provides automated, modular, and idempotent bash setup scripts for configuring a Linux desktop development environment across supported distributions:

- **Debian** (`apt`)
- **Fedora** (`dnf`)
- **Arch Linux** (`pacman`)

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
4. **[CONTRIBUTING.md](CONTRIBUTING.md)**: Ensure architecture, guidelines, or checklists are updated when appropriate.
5. **[AGENTS.md](AGENTS.md)**: Update reference notes if public behavior or AI rules changed.

---

## 🛠️ Validation & Commands

- **Run full setup**: `make all` (or `./main.sh`)
- **Run individual targets**: `make firefox`, `make fonts`, `make gitflow`, `make go`, `make neovim`, `make nvm`, `make rust`
- **Run all tests**: `make test`
- **Run unit tests only**: `make test-unit`
- **Run integration tests**: `make test-integration`
- **Run coverage reports**: `make test-coverage`
- **Lint / Validate syntax**: `shellcheck -x scripts/*.sh`
- **Clean build artifacts**: `make clean`
- **Show available targets**: `make help`

---

## 📖 Deep-Dive References

- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Architecture, script patterns, coding standards, test guidelines, and PR checklist.
- **[README.md](README.md)**: Canonical user-facing documentation and quick start.
- **[README-pt-br.md](README-pt-br.md)**: Documentação em português.
