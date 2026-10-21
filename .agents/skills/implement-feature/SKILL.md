---
name: implement-feature
description: >-
  Guide and enforce the standard workflow for creating new setup scripts, features,
  and package integrations in this repository. Use this skill whenever implementing
  a new tool setup, modifying scripts in scripts/, adding OpenSpec specs, or extending
  the setup catalog.
---

# 🚀 Feature Implementation & Setup Script Workflow

This skill defines the canonical step-by-step procedure for introducing new configurations, tools, applications, or setup modules into this repository.

> [!NOTE]
> **Skill Lifecycle & Scope**: All initial roadmap tasks (Phases 1–7) tracked in [TODO.md](../../../TODO.md) have been completed. This skill now governs ongoing maintenance, incremental enhancements, refactoring workflows, and future milestone implementations.

---

## 📋 End-to-End Implementation Lifecycle

```
[1. Study Upstream Repos] ──▶ [2. Draft Spec] ──▶ [3. Script & Packages] ──▶ [4. Bats Tests] ──▶ [5. Orchestration & Docs] ──▶ [6. Mandatory Validation (Unit + Integration)]
```

---

### Step 1: Reference Repositories & Implementation Inspiration (MANDATORY)

Before drafting any specification or script, consult the author's previous distribution setup repositories listed in [AGENTS.md — Reference Repositories](../../../AGENTS.md) (using `search_web`, `read_url_content`, or raw GitHub URLs) to understand exact packages, PPAs, dependencies, installation methods, and configurations used previously. Always adapt findings to conform to this project's modular conventions (`scripts/_utils.sh`, `packages.conf`, idempotency, and automated tests).

---

### Step 2: Spec-Driven Development (Autonomous Drafting)

1. **Target Identification from TODO.md**:
   - Identify the specific target task/feature requested from [TODO.md](../../../TODO.md) along with its phase, dependencies, and requirements.
2. **Draft Specification**:
   - Create or update the feature specification file under `openspec/specs/<domain>/<feature>.md` based directly on the requested item in `TODO.md` and the findings from reference repos.
   - Document the requirements, constraints, package dependencies, and testable scenarios using the **GIVEN / WHEN / THEN** syntax across supported distros (Debian, Fedora, Arch Linux).
3. **Autonomous Implementation**:
   - Per `AGENTS.md`, AI agents have permission to proceed directly with script implementation, package mapping, tests, and documentation autonomously without waiting for explicit approval.
   - **Exception**: Any modifications to **Protected Core Governance Files** (`AGENTS.md`, `CONTRIBUTING.md`, `.agents/skills/**`) strictly require explicit prior user confirmation.

---

### Step 3: Implementation & Package Mapping

#### A. Script Implementation (`scripts/<domain>/setup-<feature>.sh`)

Follow the script conventions from [CONTRIBUTING.md](../../../CONTRIBUTING.md):

- **Shebang, Strict Mode & Fail-Fast**: Start with `#!/bin/bash` and `set -euo pipefail`. Scripts must **fail-fast** — any failure halts execution immediately. Do not suppress errors blindly (avoid unchecked `|| true` unless the failure is explicitly optional and safely handled).
- **Helper Sourcing**: Source helpers near the top: `source "scripts/_utils.sh" 2>/dev/null || true`.
- **Public Utilities & Helper Catalog (`scripts/_utils.sh`)**:
  Always reuse existing helpers from `scripts/_utils.sh` (`scripts/utils/*.sh`) instead of reimplementing or calling raw tools directly:
  1. [`get_distro_id`](../../../scripts/_utils.sh): Returns current distribution identifier (`debian`, `fedora`, `arch`, `opensuse`, or `unknown`).
  2. [`is_distro <distro>`](../../../scripts/_utils.sh): Checks whether current system matches target distribution.
  3. [`install_packages <pkg1> [pkg2...]`](../../../scripts/_utils.sh): Resolves packages via `packages.conf` across distributions (`debian`, `fedora`, `arch`, `opensuse`) and installs them idempotently.
  4. [`install_packages_from_repo <repo> <pkg1> [pkg2...]`](../../../scripts/_utils.sh): Resolves packages via `packages.conf` and installs them targeting a specific repository (`apt -t`, `zypper --from`, or fallback).
  5. [`swap_packages <old_pkg> <new_pkg>`](../../../scripts/_utils.sh): Atomically swaps conflicting packages (`dnf swap --allowerasing` on Fedora, or `install_packages` fallback).
  6. [`remove_packages <pkg1> [pkg2...]`](../../../scripts/_utils.sh): Removes installed packages idempotently across distributions.
  7. [`upgrade_system`](../../../scripts/_utils.sh): Refreshes repository metadata and upgrades installed system packages across distributions.
  8. [`lock_packages <pkg1> [pkg2...]`](../../../scripts/_utils.sh): Locks/holds packages against unintended upgrades.
  9. [`install_flatpak_app <app_id> [app_name]`](../../../scripts/_utils.sh): Ensures Flatpak/Flathub is configured and idempotently installs Flatpak applications.
  10. [`download_file <url> <dest>`](../../../scripts/_utils.sh): Downloads remote files to a destination path with automatic `curl` / `wget` fallback and fail-fast validation.
  11. [`fetch_url <url>`](../../../scripts/_utils.sh): Fetches remote content directly to stdout with `curl` / `wget` fallback.
  12. [`get_desktop_environment`](../../../scripts/_utils.sh): Detects current desktop environment (`gnome`, `plasma`, or `unknown`).
  13. [`configure_de_wallpaper <wallpaper_path>`](../../../scripts/_utils.sh): Sets the desktop wallpaper idempotently on GNOME or KDE Plasma.
  14. [`get_root_filesystem`](../../../scripts/_utils.sh): Returns root filesystem type (e.g. `btrfs`, `ext4`, or `unknown`).
  15. [`get_shell_profile`](../../../scripts/_utils.sh): Resolves user configuration file path based on `$SHELL` (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).
  16. [`get_gpu_vendor`](../../../scripts/_utils.sh): Detects physical GPU vendor (`nvidia`, `amd`, `intel`, or `unknown`).
  17. [`enable_cron_service [service_name]`](../../../scripts/_utils.sh): Enables and starts distribution cron service (`cron` on Debian, `crond` on Fedora, `cronie` on Arch/openSUSE).
  18. [`require_supported_distro`](../../../scripts/_utils.sh): Validates that current system is supported (`debian`, `fedora`, `arch`, `opensuse`) and prints distro ID; exits 1 otherwise.
  19. [`fetch_github_latest_version <owner/repo>`](../../../scripts/_utils.sh): Resolves latest release tag from GitHub with resilient fallback against API rate limits.
  20. [`is_version_up_to_date <local_ver> <remote_ver>`](../../../scripts/_utils.sh): Compares local and remote version strings idempotently.
  21. [`install_github_binary <name> <repo> <version> <file_name> <bin_name>`](../../../scripts/_utils.sh): Downloads, extracts, and installs a GitHub tarball binary to `/usr/local/bin`.
- **Distribution-Specific Repository & Hardware Utilities**:
  When configuring third-party or upstream repositories and hardware detection, reuse or register functions in:
  - **Shared GPU Utilities (`scripts/system/_gpu_utils.sh`)**: `has_nvidia_gpu`, `has_amd_gpu`, `has_intel_gpu`, `has_hybrid_gpu`, `configure_gpu_repositories`.
  - **Shared System Helpers**: `scripts/system/_grub_btrfs.sh` (`configure_grub_btrfs`), `scripts/system/_debloat_packages.sh`.
  - **Arch Linux (`scripts/system/arch/_repositories.sh`)**: `add_arch_multilib_repo`.
  - **Debian (`scripts/system/debian/_repositories.sh`)**: `get_debian_codename`, `add_debian_backports_repo`, `add_debian_vscodium_repo`, `add_debian_mozilla_repo`, `add_debian_nonfree_repo`.
  - **Fedora (`scripts/system/fedora/_repositories.sh`)**: `add_fedora_docker_repo`, `add_fedora_vscodium_repo`, `add_fedora_rpmfusion_repo`.
  - **openSUSE (`scripts/system/opensuse/_repositories.sh` & `_snapper.sh`)**: `add_opensuse_packman_repo`, `add_opensuse_nvidia_repo`, `add_opensuse_vscodium_repo`, `configure_opensuse_snapper`.
- **Helper Function Conventions**:
  - Prefix script-private functions with `_` (e.g., `_configure_app`).
  - **No trivial one-line wrappers**: Do not create one-line functions that merely proxy a call if used only once. Inline the helper call directly.
  - **Desktop Environment Handling**: When a step depends on DE, check `get_desktop_environment` (`gnome`, `plasma`). If `unknown`, do not execute DE-specific actions.
  - **SOLID Principles**: All scripts must strictly apply SOLID (Single Responsibility per function, Open/Closed via packages.conf and `get_distro_id` dispatch, Liskov Substitution across distros, Interface Segregation via granular repo helpers, and Dependency Inversion via `_utils.sh` abstractions).
- **Entrypoint & Execution Guard**: Expose `main()` and guard direct execution with `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`.

##### ✅ Canonical Script Template

```bash
#!/bin/bash
set -euo pipefail
source "scripts/_utils.sh" 2> /dev/null || true

_install_packages() {
  # ✅ Use install_packages — never apt/dnf/pacman directly
  install_packages foo bar
}

_configure_de_specific() {
  # ✅ Always detect DE; do nothing for unknown
  local de
  de="$(get_desktop_environment)"
  case "$de" in
    gnome) gsettings set org.example.key value ;;
    plasma) kwriteconfig6 --file ... ;;
    *) echo "Unknown DE, skipping DE-specific config." ;;
  esac
}

_install_distro_specific() {
  case "$(get_distro_id)" in
    debian)
      source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
      add_debian_example_repo
      install_packages example-pkg
      ;;
    fedora)
      source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
      add_fedora_example_repo
      install_packages example-pkg
      ;;
    arch)
      install_packages example-pkg
      ;;
    *)
      echo "Unsupported distribution, skipping."
      return 0
      ;;
  esac
}

main() {
  _install_packages
  _configure_de_specific
  _install_distro_specific
}

# ✅ Execution guard — allows sourcing in test suites
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

##### ❌ Common Anti-Patterns to Avoid

```bash
# ❌ Raw package manager call — breaks on other distros
sudo apt install -y ripgrep fd-find

# ❌ Assumes GNOME — crashes on Plasma/unknown
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# ❌ Trivial one-line wrapper used only once — inline it instead
_install_pkg() { install_packages ripgrep; }
_install_pkg

# ❌ Missing execution guard — breaks when sourced in tests
main "$@" # At the end of file with no BASH_SOURCE check
```

#### B. Cross-Distro Package Mapping (`scripts/packages.conf`)

Add an entry to `scripts/packages.conf` when package names differ across distributions or a package is unsupported on a specific distro. Follow the format and rules defined in [CONTRIBUTING.md § Package Mappings](../../../CONTRIBUTING.md#-package-mappings-scriptspackagesconf): format is `GENERIC_NAME | DEBIAN | FEDORA | ARCH`, use `-` for unsupported distros, maintain alphabetical order and column alignment, do **not** add packages with identical names across all three distributions.

---

### Step 4: Automated Tests & Full Branch Coverage (Bats)

All code paths and conditional branches must be thoroughly tested:

1. **Unit Tests (`tests/unit/<domain>/<feature>.bats`)**:
   - **100% Branch Coverage**: Test all `if`/`elif`/`else` branches, error cases, and distro branches (`debian`, `fedora`, `arch`, unsupported distro).
   - Test Desktop Environment conditionals (`gnome`, `plasma`, `unknown`).
   - Mock external utilities and verify flag logic, package manager resolution, and fail-fast/exit-code behavior on errors.
2. **Integration Tests (`tests/integration/<domain>/<feature>.bats`)**:
   - Test end-to-end execution inside clean containers across all supported distributions (**Debian 13**, **Fedora 44**, **Arch Linux**).
   - Validate idempotency: running the script a second time must succeed without errors or redundant modifications.

---

### Step 5: Orchestration, CLI Registration & Documentation

1. **Master CLI & Orchestrator (`runners/_modules.sh`, `runners/main.sh` / `main.sh`)**:
   - Register the module invocation in the appropriate distro runner(s) under `runners/` (`arch.sh`, `debian.sh`, `fedora.sh`, `opensuse.sh`) or shared pipeline arrays in `runners/_utils.sh` if it belongs to the automated complete setup.
   - Register the module in `runners/_modules.sh` (`MODULE_CATALOG`, `MODULE_SCRIPTS`, and `MODULE_DESCRIPTIONS`) for standalone execution (e.g. `./main.sh <feature>` and `make <feature>`) and CLI help generation. **The declarative registry in `runners/_modules.sh` rendered by `show_help()` in `runners/main.sh` is the single source of truth for all available setup commands.**
2. **Roadmap & Tracking (`TODO.md`)**:
   - Mark the corresponding task item as done `[x]` with script references.
3. **Skill Synchronization**:
   - **`.agents/skills/implement-feature/SKILL.md`**: **Mandatory Update**: If any new reusable helper or utility is added to `scripts/_utils.sh` or `runners/_utils.sh`, it must be immediately documented in this skill with its signature and purpose.

---

### Step 6: Mandatory Validation Execution (MANDATORY GATE BEFORE COMPLETION)

Before marking any implementation as finished or reporting completion to the user, the AI agent **MUST ALWAYS execute and pass all tests related to the feature**, without exceptions:

> [!CAUTION]
> **Docker-Only Execution**: Integration tests and any script-level validation **MUST** run inside the correct distro Docker containers — never on the developer's host machine. Unit tests (mocked) are safe to run on the host. Running setup scripts directly on the host may corrupt the developer's system.

1. **Unit Tests for the Feature & Modified Modules** _(safe on host — mocked)_:

   ```bash
   ./tests/run-tests.sh --unit --filter=<feature>
   ```

   _Verify that all unit test cases for the feature pass with 100% branch coverage._

2. **Integration Tests for the Feature (Multi-Distro Validation)** _(runs inside Docker)_:

   ```bash
   ./tests/run-tests.sh --integration --filter=<feature>
   ```

   _Validate execution inside Debian 13, Fedora 44, and Arch Linux containers. All distro containers must succeed._

3. **Full Unit Test Suite (Regression Prevention)** _(safe on host — mocked)_:

   ```bash
   make test-unit
   ```

   _Ensure no regressions were introduced to other modules._

4. **Linting & Formatting** _(safe on host)_:

   ```bash
   make lint && make format
   ```

> [!IMPORTANT]
> **Completion Invariant**: An implementation is strictly considered **INCOMPLETE** until all relevant unit and multi-distro integration tests have been actively run, verified green, and reported.
> For commit and push policies, see [AGENTS.md — Commit Policy](../../../AGENTS.md).
