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

- `get_desktop_environment`: Returns current desktop environment (`gnome`, `plasma`, or `unknown`).
- `get_root_filesystem`: Returns root partition filesystem type (`btrfs`, `ext4`, etc.).
- `get_shell_profile`: Returns user profile path (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).
- `install_flatpak_app <app_id> [app_name]`: Idempotently configures Flatpak and installs Flathub applications.
- `download_file <url> <dest>`: Downloads file with transparent `curl` / `wget` fallback.
- `fetch_url <url>`: Fetches remote content directly with `curl` / `wget` fallback.

### 3. Distribution-Specific Repository Utilities

Third-party repository configurations must reside in their respective distro helper modules:

- **Debian (`scripts/system/debian/_repositories.sh`)**:
  - `_get_debian_codename`: Resolves Debian release codename (`trixie`, `bookworm`, etc.).
  - `add_debian_backports_repo`: Idempotently configures Debian Backports.
  - `add_debian_vscodium_repo`: Idempotently imports GPG key and adds VSCodium APT source.
  - `add_debian_mozilla_repo`: Idempotently imports Mozilla GPG key, adds source, and sets APT pinning priority.
- **Fedora (`scripts/system/fedora/_repositories.sh`)**:
  - `add_fedora_docker_repo`: Idempotently adds Docker CE DNF repository.
  - `add_fedora_vscodium_repo`: Idempotently adds VSCodium DNF repository.

### 4. Rule for One-Line Functions

- **Do NOT create trivial one-line wrapper functions** if they are called in only one place and simply proxy a call. Inline the command/helper directly at the call site.
- **Exception**: One-line functions are permitted if they are called from multiple locations or provide meaningful semantic reuse.

### 5. Desktop Environment (DE) Handling Policy

- Whenever a script or configuration step depends on a specific Desktop Environment (GNOME, KDE Plasma), it must detect the active environment using `get_desktop_environment`.
- **Default to doing nothing**: When the Desktop Environment is not recognized (`unknown` or unsupported), the script must **NOT** execute environment-specific actions or guess configurations. Agnóstic/generic configurations (like standard XDG specifications) may still proceed.

---

## 🚫 AI Operational Rules & Commit Policy

- **Autonomous File Edits & Protected Core Files**: AI agents have full permission to create and modify codebase files, scripts, configurations, tests, OpenSpec specs, and documentation autonomously **without requesting confirmation**, with the strict exception of **Protected Core Governance Files**:
  - `AGENTS.md`
  - `CONTRIBUTING.md`
  - `.agents/skills/**`
    Modifying any of these three protected files/directories strictly requires explicit prior approval from the human developer.
- **Commit Policy & Standards (Conventional Commits v1.0.0)**: AI assistants and agents may execute `git commit` **only when explicitly requested or authorized by the human developer**. All commit messages must strictly adhere to the [Conventional Commits v1.0.0 specification](https://www.conventionalcommits.org/en/v1.0.0/) (`<type>[optional scope]: <description>`, followed by optional body and footers). Autonomous or unsolicited commits and `git push` operations remain strictly prohibited without explicit developer approval.
- **Developer Oversight**: Commits performed by AI agents must strictly reflect the requested changes, follow clean semantic messages conforming to Conventional Commits, and leave push/remote operations under developer discretion unless explicitly instructed.
- **Mandatory Lint & Test Execution**: After creating or modifying any executable script (`scripts/*.sh`), orchestration script (`main.sh`), configuration, or Bats test (`tests/**/*.bats`), AI agents must **ALWAYS** run and fix:
  1. `shellcheck` across all modified scripts and test files (`shellcheck -x scripts/*.sh main.sh tests/*.sh` and `shellcheck --severity=warning tests/unit/*.bats tests/integration/*.bats`).
  2. The unit test suite (`make test-unit` or `./tests/run-tests.sh --unit`).
  3. The relevant integration tests if containers/Docker are available (`./tests/run-tests.sh --integration --filter=<feature>`).
- **Doc-Only Optimization**: If changes are strictly limited to documentation or markdown files (`*.md`, `TODO.md`, `README*.md`, `CONTRIBUTING.md`, `AGENTS.md`) with no changes to code, configurations, or tests, AI agents must **NOT** execute the test or lint suites.

---

## 📋 Mandatory Documentation, OpenSpec & Package Mapping Rules

Whenever a new script is added or an existing script/flow is modified under `scripts/`, `main.sh`, or `Makefile`:

1. **[OpenSpec](openspec/)**: Follow Spec-Driven Development (SDD). Ensure the corresponding capability spec under `openspec/specs/<domain>/<feature>.md` is created or updated with requirements and GIVEN/WHEN/THEN scenarios BEFORE implementing or modifying code.
2. **[TODO.md](TODO.md)**: Check off completed tasks (`[x]`) and reference the implemented script file. AI agents must consult this file to plan upcoming work following the established phase priority order.
3. **[main.sh](main.sh)**: Register the new module in `run_module()`, `run_all()` steps, and the `show_help()` documentation. The CLI help in `main.sh` is the single source of truth for available setup commands.
4. **[scripts/packages.conf](scripts/packages.conf)** (Package Mappings):
   - Only add entries to `packages.conf` when the package name differs across package managers (`apt`, `dnf`, `pacman`) or is unsupported (`-`) in a specific distro. Packages with identical names across all distros are resolved automatically by fallback and must NOT be added.
   - Maintain alphabetical order by generic package name.
   - Maintain column alignment and strictly ensure at least one blank space before and after every `|` separator.

---

## 🛠️ Validation & Commands

- **Run full setup**: `make all` (or `./main.sh all` / `./main.sh`)
- **Run individual targets**: `make <module>` (e.g. `make neovim`, `make docker`, `make firewall` or `./main.sh <module>`)
- **Show available targets & modules**: `make help` (or `./main.sh help`)
- **Run all tests**: `make test`
- **Run unit tests only**: `make test-unit`
- **Run integration tests**: `make test-integration`
- **Run coverage reports**: `make test-coverage`
- **Clean build artifacts**: `make clean`

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
