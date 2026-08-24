# 🤖 AI Agent Guidelines & Context — Desktop Setup

This file is the authoritative source of truth for AI assistants, coding agents, and maintainers regarding operational rules, AI constraints, and mandatory synchronization policies.

For script conventions, repository layout, developer contribution guides, and integration test specifications, refer directly to:
👉 **[CONTRIBUTING.md](CONTRIBUTING.md)**

---

## 📌 Project Overview

This repository provides automated, modular, and idempotent bash setup scripts for configuring a Linux desktop development environment across supported distributions:

- **Debian 13 (Trixie)** (`apt`)
- **Fedora 44** (`dnf`)
- **Arch Linux** (`pacman` / Rolling release)

---

## 📐 Architecture, Conventions & Coding Standards

### 1. Modern Tooling & Package Management
- Use `apt` (never legacy `apt-get`) on Debian.
- Always use `install_packages <generic_pkg>` to automatically resolve package manager differences via `packages.conf`.

### 2. Common Reusable Utilities (`scripts/_utils.sh`)
Common operations must reuse helper functions from `scripts/_utils.sh`:
- `get_root_filesystem`: Returns root partition filesystem type (`btrfs`, `ext4`, etc.).
- `get_shell_profile`: Returns user profile path (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).
- `install_flatpak_app <app_id> [app_name]`: Idempotently configures Flatpak and installs Flathub applications.
- `download_file <url> <dest>`: Downloads file with transparent `curl` / `wget` fallback.
- `fetch_url <url>`: Fetches remote content directly with `curl` / `wget` fallback.

### 3. Rule for One-Line Functions
- **Do NOT create trivial one-line wrapper functions** if they are called in only one place and simply proxy a call. Inline the command/helper directly at the call site.
- **Exception**: One-line functions are permitted if they are called from multiple locations or provide meaningful semantic reuse.

---

## 🚫 AI Operational Rules & Commit Policy

- **No Automated Commits**: AI assistants and agents must **NEVER** execute `git commit`, `git push`, or alter git history directly.
- **Developer Ownership**: All commits must be made exclusively by the human developer after reviewing and validating the changes.
- **Mandatory Lint & Test Execution**: After creating or modifying any executable script (`scripts/*.sh`), orchestration script (`main.sh`), configuration, or Bats test (`tests/**/*.bats`), AI agents must **ALWAYS** run and fix:
  1. `shellcheck` across all modified scripts and test files (`shellcheck -x scripts/*.sh main.sh tests/*.sh` and `shellcheck --severity=warning tests/unit/*.bats tests/integration/*.bats`).
  2. The unit test suite (`make test-unit` or `./tests/run-tests.sh --unit`).
  3. The relevant integration tests if containers/Docker are available (`./tests/run-tests.sh --integration --filter=<feature>`).
- **Doc-Only Optimization**: If changes are strictly limited to documentation or markdown files (`*.md`, `TODO.md`, `README*.md`, `CONTRIBUTING.md`, `AGENTS.md`) with no changes to code, configurations, or tests, AI agents must **NOT** execute the test or lint suites.

---

## 📋 Mandatory Documentation & Package Mapping Rules

Whenever a new script is added or an existing script/flow is modified under `scripts/`, `main.sh`, or `Makefile`:

1. **[TODO.md](TODO.md)**: Check off completed tasks (`[x]`) and reference the implemented script file. AI agents must consult this file to plan upcoming work following the established phase priority order.
2. **[Makefile](Makefile)**: Add the target with help documentation. Targets must be ordered alphabetically with `help` and `all` at the top and `clean` at the bottom.
3. **[README.md](README.md)**: Update the "Quick start" section maintaining the same alphabetical target order.
4. **[README-pt-br.md](README-pt-br.md)**: Update the "Como usar (rápido)" section matching the English README.
5. **[CONTRIBUTING.md](CONTRIBUTING.md)**: Ensure architecture, guidelines, or checklists are updated when appropriate.
6. **[AGENTS.md](AGENTS.md)**: Update reference notes if public behavior or AI rules changed.
7. **[scripts/packages.conf](scripts/packages.conf)** (Package Mappings):
   - Only add entries to `packages.conf` when the package name differs across package managers (`apt`, `dnf`, `pacman`) or is unsupported (`-`) in a specific distro. Packages with identical names across all distros are resolved automatically by fallback and must NOT be added.
   - Maintain alphabetical order by generic package name.
   - Maintain column alignment and strictly ensure at least one blank space before and after every `|` separator.

---

## 🛠️ Validation & Commands

- **Run full setup**: `make all` (or `./main.sh`)
- **Run individual targets**: `make browsers`, `make docker`, `make fonts`, `make gitflow`, `make go`, `make neovim`, `make nvm`, `make rust`
- **Run all tests**: `make test`
- **Run unit tests only**: `make test-unit`
- **Run integration tests**: `make test-integration`
- **Run coverage reports**: `make test-coverage`
- **Lint / Validate syntax**: `shellcheck -x scripts/*.sh`
- **Clean build artifacts**: `make clean`
- **Show available targets**: `make help`

---

## 📖 Deep-Dive References & Upstream Sources

- **[TODO.md](TODO.md)**: Master task list, milestone priorities, and execution roadmap.
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Architecture, script patterns, coding standards, test guidelines, and PR checklist.
- **[README.md](README.md)**: Canonical user-facing documentation and quick start.
- **[README-pt-br.md](README-pt-br.md)**: Documentação em português.

### 📚 Author's Reference Repositories (Implementation Inspiration)

When implementing new features or migrating legacy configurations, AI agents should consult the author's previous distribution setup repositories (using `search_web`, `read_url_content`, or raw GitHub URLs) to understand exact packages, commands, PPAs, or desktop configurations used previously:

- **Arch Linux**: [gabrielscaranello/arch-setup](https://github.com/gabrielscaranello/arch-setup)
- **Debian**: [gabrielscaranello/debian](https://github.com/gabrielscaranello/debian)
- **Fedora**: [gabrielscaranello/fedora-setup](https://github.com/gabrielscaranello/fedora-setup)
- **Linux Mint**: [gabrielscaranello/mint-setup](https://github.com/gabrielscaranello/mint-setup)
- **openSUSE**: [gabrielscaranello/opensuse](https://github.com/gabrielscaranello/opensuse)
- **Zorin OS**: [gabrielscaranello/zorin-setup](https://github.com/gabrielscaranello/zorin-setup)
- **Dotfiles**: [gabrielscaranello/dotfiles](https://github.com/gabrielscaranello/dotfiles)

> [!TIP]
> When porting features from these reference repos, always adapt them to follow this project's modular conventions (`scripts/_utils.sh`, `packages.conf`, idempotency, and unit/integration tests).
