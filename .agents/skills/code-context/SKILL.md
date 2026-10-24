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
├── _utils.sh          ← Core abstractions (sources scripts/utils/*.sh; ALWAYS use these, never raw pkg managers)
├── packages.conf      ← Cross-distro package name mappings (add only when names differ)
├── utils/             ← Modular core helpers (_packages.sh, _system.sh, _desktop.sh, _download.sh, _terminal.sh)
├── apps/              ← GUI app setup scripts
├── desktop/           ← DE theming/extension scripts
├── security/          ← Security tooling
├── system/            ← OS-level config (drivers, repos, kernel)
│   ├── _debloat_packages.sh      ← Declarative bloatware lists per distro
│   ├── _gpu_utils.sh             ← Shared GPU utilities (hardware detection & configure_gpu_repositories)
│   ├── _grub_btrfs.sh            ← Shared GRUB Btrfs snapshot menu integration
│   ├── arch/_repositories.sh     ← Arch-specific repo helpers
│   ├── debian/_repositories.sh   ← Debian-specific repo helpers
│   ├── fedora/_repositories.sh   ← Fedora-specific repo helpers
│   └── opensuse/                 ← openSUSE-specific repo & Snapper helpers
├── terminal/          ← Terminal emulators, fonts
└── toolchain/         ← Dev runtimes (nvm, go, rust, etc.)

runners/
├── _modules.sh          ← Declarative module registry & CLI descriptions (single source of truth)
├── _utils.sh            ← Shared steps (COMMON_INITIAL_STEPS, COMMON_POST_STEPS) & run_pipeline
├── main.sh              ← Central CLI dispatcher
├── arch.sh / debian.sh / fedora.sh / opensuse.sh / wsl.sh  ← Distro & environment pipelines

tests/
├── docker/            ← Base Dockerfiles: archlinux.Dockerfile, debian.Dockerfile, fedora.Dockerfile, opensuse.Dockerfile, tumbleweed.Dockerfile
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
bash scripts/toolchain/setup-docker.sh
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

Only add a package to `packages.conf` when its name **differs** across Debian / Fedora / Arch / openSUSE, or when it is **unsupported** (`-`) on a specific distro. Packages with identical names everywhere are resolved automatically by fallback.

```
# ✅ CORRECT — names differ across distros
fd-find | fd-find | fd-find | fd | fd

# ✅ CORRECT — unsupported on one distro
timeshift | timeshift | - | timeshift | -

# ❌ WRONG — same name everywhere, do not add to packages.conf
# ripgrep | ripgrep | ripgrep | ripgrep | ripgrep
```

Format: `GENERIC_NAME | DEBIAN | FEDORA | ARCH | OPENSUSE` — maintain alphabetical order and column alignment with at least one space around each `|`.

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

### `scripts/_utils.sh` (`scripts/utils/*.sh`) — Core Helpers

| Function                      | Signature                                                | Purpose                                                                              |
| ----------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `get_distro_id`               | `get_distro_id`                                          | Returns `debian`, `fedora`, `arch`, `opensuse`, or `unknown`                         |
| `require_supported_distro`    | `require_supported_distro`                               | Validates supported distro (`debian/fedora/arch/opensuse`)                           |
| `is_distro`                   | `is_distro <name>`                                       | Returns 0 if current distro matches                                                  |
| `is_wsl`                      | `is_wsl`                                                 | Detects whether current environment is Windows Subsystem for Linux                   |
| `install_packages`            | `install_packages <pkg>...`                              | Cross-distro package install via packages.conf                                       |
| `install_packages_from_repo`  | `install_packages_from_repo <repo> <pkg>...`             | Installs packages targeting a specific repository suite (`apt -t` / `zypper --from`) |
| `swap_packages`               | `swap_packages <old_pkg> <new_pkg>`                      | Atomically swaps conflicting packages (`dnf swap` with fallback)                     |
| `remove_packages`             | `remove_packages <pkg>...`                               | Cross-distro idempotent package removal                                              |
| `upgrade_system`              | `upgrade_system`                                         | Refreshes repo metadata and upgrades system packages                                 |
| `lock_packages`               | `lock_packages <pkg>...`                                 | Locks packages against unintended upgrades on openSUSE (`zypper addlock`)            |
| `is_package_installed`        | `is_package_installed <pkg>`                             | Checks whether a native package is installed                                         |
| `get_desktop_environment`     | `get_desktop_environment`                                | Returns `gnome`, `plasma`, or `unknown`                                              |
| `save_desktop_environment`    | `save_desktop_environment <de>`                          | Persists desktop environment selection                                               |
| `prompt_desktop_environment`  | `prompt_desktop_environment [prompt] [def]`              | Prompts user for DE selection in terminal                                            |
| `ensure_desktop_environment`  | `ensure_desktop_environment [prompt]`                    | Resolves, prompts, and persists DE                                                   |
| `resolve_desktop_app`         | `resolve_desktop_app <candidates...>`                    | Finds first matching `.desktop` entry across standard XDG paths                      |
| `get_root_filesystem`         | `get_root_filesystem`                                    | Returns `btrfs`, `ext4`, etc.                                                        |
| `get_repo_root`               | `get_repo_root`                                          | Returns absolute root directory of repository                                        |
| `write_ini_key`               | `write_ini_key <file> <section> <k> <v>`                 | Safely edits or appends keys in INI/.desktop files                                   |
| `get_shell_profile`           | `get_shell_profile`                                      | Returns `~/.zshrc`, `~/.bashrc`, or `~/.profile`                                     |
| `get_gpu_vendor`              | `get_gpu_vendor`                                         | Returns `nvidia`, `amd`, `intel`, or `unknown`                                       |
| `enable_cron_service`         | `enable_cron_service [service]`                          | Enables and starts distribution cron service                                         |
| `ensure_xdg_terminal_exec`    | `ensure_xdg_terminal_exec`                               | Deploys `xdg-terminal-exec` and terminal symlinks                                    |
| `install_flatpak_app`         | `install_flatpak_app <app_id> [name]`                    | Idempotently installs a Flatpak app from Flathub                                     |
| `download_file`               | `download_file <url> <dest>`                             | Downloads file (curl/wget fallback)                                                  |
| `fetch_url`                   | `fetch_url <url>`                                        | Fetches URL to stdout (curl/wget fallback)                                           |
| `fetch_github_latest_version` | `fetch_github_latest_version <owner/repo>`               | Resolves release tag from GitHub (rate-limit resilient)                              |
| `is_version_up_to_date`       | `is_version_up_to_date <local> <remote>`                 | Compares versions idempotently                                                       |
| `install_github_binary`       | `install_github_binary <name> <repo> <ver> <file> <bin>` | Installs GitHub release archive binary                                               |

### Distro-Specific Repo & Hardware Helpers

| Distro     | File                                                       | Functions                                                                                                                                                                                                                                   |
| ---------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| All (GPU)  | `scripts/system/_gpu_utils.sh`                             | `has_nvidia_gpu`, `has_amd_gpu`, `has_intel_gpu`, `has_hybrid_gpu`, `configure_gpu_repositories`                                                                                                                                            |
| All (Sys)  | `scripts/system/_grub_btrfs.sh`                            | `configure_grub_btrfs`                                                                                                                                                                                                                      |
| Arch Linux | `scripts/system/arch/_repositories.sh`                     | `add_arch_multilib_repo`                                                                                                                                                                                                                    |
| Debian     | `scripts/system/debian/_repositories.sh`                   | `get_debian_codename`, `is_debian_testing`, `add_debian_backports_repo`, `add_debian_vscodium_repo`, `add_debian_mozilla_repo`, `add_debian_nonfree_repo`                                                                                   |
| Fedora     | `scripts/system/fedora/_repositories.sh`                   | `add_fedora_docker_repo`, `add_fedora_vscodium_repo`, `add_fedora_rpmfusion_repo`                                                                                                                                                           |
| openSUSE   | `scripts/system/opensuse/_repositories.sh` & `_snapper.sh` | `get_opensuse_version`, `add_opensuse_packman_repo`, `add_opensuse_nonfree_repo`, `add_opensuse_nvidia_repo`, `add_opensuse_vscodium_repo`, `add_opensuse_mozilla_repo`, `add_opensuse_kernel_backports_repo`, `configure_opensuse_snapper` |

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
- [scripts/_utils.sh](../../scripts/_utils.sh) — All available helper functions
- [scripts/packages.conf](../../scripts/packages.conf) — Cross-distro package mappings
