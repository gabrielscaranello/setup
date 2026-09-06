---
name: code-context
description: >-
  Quick-reference context skill for any task in this repository. Provides a
  scannable summary of critical rules, anti-patterns with correct alternatives,
  canonical code examples, and the execution environment contract (Docker-only
  for script testing). Activate this skill at the start of any task — debugging,
  refactoring, reviewing, or implementing — to prevent the most common AI agent
  mistakes.
---

# 🗺️ Repository Code Context & Critical Rules

This skill is the **first thing to activate** before any task in this repository. It distills the most important rules from [AGENTS.md](../../AGENTS.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md) into a scannable reference.

> [!IMPORTANT]
> Full governance rules live in [AGENTS.md](../../AGENTS.md). This skill provides a fast-access summary; always resolve conflicts by deferring to `AGENTS.md`.

---

## 🗂️ Repository Layout at a Glance

```
scripts/
├── _utils.sh          ← Core abstractions (ALWAYS use these, never raw pkg managers)
├── packages.conf      ← Cross-distro package name mappings (add only when names differ)
├── apps/              ← GUI app setup scripts
├── desktop/           ← DE theming/extension scripts
├── security/          ← Security tooling
├── system/            ← OS-level config (drivers, repos, kernel)
│   ├── debian/_repositories.sh  ← Debian-specific repo helpers
│   └── fedora/_repositories.sh  ← Fedora-specific repo helpers
├── terminal/          ← Terminal emulators, fonts
└── toolchain/         ← Dev runtimes (nvm, go, rust, etc.)

runners/
├── main.sh            ← Central CLI dispatcher (single source of truth for commands)
├── arch.sh / debian.sh / fedora.sh  ← Distro-specific pipelines

tests/
├── docker/            ← Base Dockerfiles: archlinux.Dockerfile, debian.Dockerfile, fedora.Dockerfile
├── unit/              ← Fast Bats unit tests (mocked, no real installs)
└── integration/       ← E2E Bats tests (run inside Docker containers)
```

---

## 🐳 RULE #1 — Docker-Only Execution Contract (Most Critical)

> **Never run setup scripts or investigate script behavior on the host machine.**
> The host is a developer workstation. All script execution, testing, and validation must happen inside the correct distro containers.

```bash
# ✅ Run unit tests — fast, mocked, safe on host
make test-unit
./tests/run-tests.sh --unit --filter=<feature>

# ✅ Run integration tests — MUST run inside Docker, never on host
make test-integration
./tests/run-tests.sh --integration --filter=<feature>

# ✅ Run integration tests for a specific distro
./tests/run-tests.sh --integration --distro=debian --filter=<feature>

# ✅ Manually explore a distro container for debugging
docker run --rm -it -v "$(pwd)":/setup setup-test-debian bash
docker run --rm -it -v "$(pwd)":/setup setup-test-fedora bash
docker run --rm -it -v "$(pwd)":/setup setup-test-archlinux bash

# ❌ NEVER — runs on the developer's host machine, may corrupt their system
bash scripts/setup-docker.sh
sudo bash scripts/system/setup-nvidia.sh
./scripts/apps/setup-browsers.sh
```

> [!CAUTION]
> Running setup scripts on the host can permanently alter the developer's system configuration, install unwanted packages, or overwrite personal settings. **Always use containers.**

---

## 🔧 RULE #2 — Package Installation Abstraction

Always use `install_packages` from `scripts/_utils.sh`. Never call `apt`, `dnf`, or `pacman` directly.

```bash
# ✅ CORRECT — resolves name differences via packages.conf automatically
source "scripts/_utils.sh" 2> /dev/null || true
install_packages ripgrep fd neovim

# ❌ WRONG — hard-codes package manager, breaks on other distros
sudo apt install -y ripgrep fd-find neovim
sudo dnf install -y ripgrep fd-find neovim
sudo pacman -S --needed --noconfirm ripgrep fd neovim
```

---

## 🖥️ RULE #3 — Desktop Environment Detection

Always detect DE with `get_desktop_environment`. Never assume GNOME or Plasma is active. Default to **doing nothing** for `unknown`.

```bash
# ✅ CORRECT
de="$(get_desktop_environment)"
case "$de" in
  gnome)
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    ;;
  plasma)
    plasma-apply-colorscheme BreezeDark
    ;;
  *)
    echo "Desktop environment not recognized, skipping DE-specific config."
    ;;
esac

# ❌ WRONG — assumes GNOME, crashes or silently fails on Plasma/unknown
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```

---

## 🚫 RULE #4 — No Trivial One-Line Wrapper Functions

Do not create functions that are used only once and simply proxy a single call.

```bash
# ✅ CORRECT — inline at the single call site
install_packages docker docker-compose-plugin

# ❌ WRONG — pointless indirection, called only once
_install_docker_packages() {
  install_packages docker docker-compose-plugin
}
_install_docker_packages
```

**Exception**: One-line functions are allowed when called from **two or more places**, or when they provide meaningful semantic abstraction.

---

## 📦 RULE #5 — `packages.conf` Discipline

Only add a package to `packages.conf` when its name **differs** across Debian / Fedora / Arch, or when it is **unsupported** (`-`) on a specific distro. Packages with identical names everywhere are resolved automatically by fallback.

```
# ✅ CORRECT — names differ across distros
fd-find | fd-find | fd-find | fd

# ✅ CORRECT — unsupported on one distro
timeshift | timeshift | - | timeshift

# ❌ WRONG — same name everywhere, do not add to packages.conf
# ripgrep | ripgrep | ripgrep | ripgrep
```

Format: `GENERIC_NAME | DEBIAN | FEDORA | ARCH` — maintain alphabetical order and column alignment with at least one space around each `|`.

---

## 🏗️ RULE #6 — Script Structure Contract

Every setup script must follow this canonical structure:

```bash
#!/bin/bash
set -euo pipefail
source "scripts/_utils.sh" 2> /dev/null || true

# Private helpers: prefix with _
_configure_something() {
  # Single responsibility — one concern per function
  install_packages foo bar
}

_setup_distro_specific() {
  case "$(get_distro_id)" in
    debian) ... ;;
    fedora) ... ;;
    arch) ... ;;
    *)
      echo "Unsupported distribution, skipping."
      return 0
      ;;
  esac
}

main() {
  _configure_something
  _setup_distro_specific
}

# Execution guard — allows sourcing in test suites without auto-running
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

---

## 🔄 RULE #7 — Idempotency

Every script must be safe to run multiple times. Use guard checks:

```bash
# ✅ Check before acting
if command -v docker > /dev/null 2>&1; then
  echo "Docker already installed, skipping."
  return 0
fi

# ✅ Package managers handle idempotency with --needed / -y flags
install_packages pkg # resolves to: pacman --needed, apt install -y, dnf install -y
```

---

## 🏛️ Repository Utility Catalog

### `scripts/_utils.sh` — Core Helpers

| Function                  | Signature                             | Purpose                                          |
| ------------------------- | ------------------------------------- | ------------------------------------------------ |
| `get_distro_id`           | `get_distro_id`                       | Returns `debian`, `fedora`, `arch`, or `unknown` |
| `is_distro`               | `is_distro <name>`                    | Returns 0 if current distro matches              |
| `install_packages`        | `install_packages <pkg>...`           | Cross-distro package install via packages.conf   |
| `get_desktop_environment` | `get_desktop_environment`             | Returns `gnome`, `plasma`, or `unknown`          |
| `get_root_filesystem`     | `get_root_filesystem`                 | Returns `btrfs`, `ext4`, etc.                    |
| `get_shell_profile`       | `get_shell_profile`                   | Returns `~/.zshrc`, `~/.bashrc`, or `~/.profile` |
| `install_flatpak_app`     | `install_flatpak_app <app_id> [name]` | Idempotently installs a Flatpak app from Flathub |
| `download_file`           | `download_file <url> <dest>`          | Downloads file (curl/wget fallback)              |
| `fetch_url`               | `fetch_url <url>`                     | Fetches URL to stdout (curl/wget fallback)       |

### Distro-Specific Repo Helpers

| Distro     | File                                     | Functions                                                                                                                            |
| ---------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Arch Linux | `scripts/system/arch/_repositories.sh`   | `add_arch_multilib_repo`                                                                                                             |
| Debian     | `scripts/system/debian/_repositories.sh` | `get_debian_codename`, `add_debian_backports_repo`, `add_debian_vscodium_repo`, `add_debian_mozilla_repo`, `add_debian_nonfree_repo` |
| Fedora     | `scripts/system/fedora/_repositories.sh` | `add_fedora_docker_repo`, `add_fedora_vscodium_repo`, `add_fedora_rpmfusion_repo`                                                    |

---

## ✅ Mandatory Validation Gates (Run After Every Script/Test Change)

```bash
# 1. Lint & format (always — on host)
make lint
make format

# 2. Unit tests (always — on host, fast)
make test-unit

# 3. Integration tests for the feature (always — inside Docker)
./tests/run-tests.sh --integration --filter=<feature>
```

> [!IMPORTANT]
> An implementation is **INCOMPLETE** until lint, unit tests, and integration tests have all passed.
> **Integration tests run inside Docker — not on the host.** Never report completion before running these gates.

---

## 🔒 Protected Files — Require Explicit Prior Approval

Modifying these files **requires explicit prior approval** from the human developer before making any changes:

- `AGENTS.md`
- `CONTRIBUTING.md`
- `.agents/skills/**`

All other codebase files, scripts, configs, tests, and docs may be created or modified autonomously.

---

## 📚 Further Reading

- [AGENTS.md](../../AGENTS.md) — Full governance rules (authoritative)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — Script patterns, test conventions, PR checklist
- [TODO.md](../../TODO.md) — Roadmap and pending work
- [scripts/_utils.sh](../../scripts/_utils.sh) — All available helper functions
- [scripts/packages.conf](../../scripts/packages.conf) — Cross-distro package mappings
