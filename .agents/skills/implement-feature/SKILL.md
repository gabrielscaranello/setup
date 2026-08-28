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
> **Skill Lifecycle & Scope**: This skill governs all ongoing feature implementations tracked in [TODO.md](../../../TODO.md). Once all roadmap tasks in `TODO.md` are completed (checklist cleared), this skill must be reviewed and updated to transition into maintenance, enhancement, or post-roadmap operational workflows.

---

## 📋 End-to-End Implementation Lifecycle

```
[1. Study Upstream Repos] ──▶ [2. Draft Spec] ──▶ 🛑 [3. USER REVIEW & APPROVAL] ──▶ [4. Script & Packages] ──▶ [5. Bats Tests] ──▶ [6. Orchestration & Docs] ──▶ [7. Mandatory Validation (Unit + Integration)]
```

---

### Step 1: Reference Repositories & Implementation Inspiration (MANDATORY)

Before drafting any specification or script, consult the author's previous distribution setup repositories (using `search_web`, `read_url_content`, or raw GitHub URLs) to understand exact packages, PPAs, dependencies, installation methods, and configurations used previously:

- **Arch Linux**: [gabrielscaranello/arch-setup](https://github.com/gabrielscaranello/arch-setup)
- **Debian**: [gabrielscaranello/debian](https://github.com/gabrielscaranello/debian)
- **Fedora**: [gabrielscaranello/fedora-setup](https://github.com/gabrielscaranello/fedora-setup)
- **Linux Mint**: [gabrielscaranello/mint-setup](https://github.com/gabrielscaranello/mint-setup)
- **openSUSE**: [gabrielscaranello/opensuse](https://github.com/gabrielscaranello/opensuse)
- **Zorin OS**: [gabrielscaranello/zorin-setup](https://github.com/gabrielscaranello/zorin-setup)
- **Dotfiles**: [gabrielscaranello/dotfiles](https://github.com/gabrielscaranello/dotfiles)

> [!TIP]
> Always adapt the findings from these reference repos to conform to this project's modular conventions (`scripts/_utils.sh`, `packages.conf`, idempotency, and automated tests).

---

### Step 2: Spec-Driven Development & User Approval Gate (MANDATORY)

1. **Target Identification from TODO.md**:
   - Identify the specific target task/feature requested from [TODO.md](../../../TODO.md) along with its phase, dependencies, and requirements.
2. **Draft Specification**:
   - Create or update the feature specification file under `openspec/specs/<domain>/<feature>.md` based directly on the requested item in `TODO.md` and the findings from reference repos.
   - Document the requirements, constraints, package dependencies, and testable scenarios using the **GIVEN / WHEN / THEN** syntax across supported distros (Debian, Fedora, Arch Linux).
3. 🛑 **User Spec Review Gate (DO NOT PROCEED WITHOUT APPROVAL)**:
   - Present the drafted specification to the user.
   - **STOP execution and explicitly ask the user for feedback/approval** before writing any script code (`scripts/*.sh`) or modifying tests/configurations.
   - Proceed to implementation ONLY after the user approves the specification.

---

### Step 3: Implementation & Package Mapping

#### A. Script Implementation (`scripts/setup-<feature>.sh`)

Follow the script conventions from [CONTRIBUTING.md](../../../CONTRIBUTING.md):

- **Shebang, Strict Mode & Fail-Fast Behavior**:
  ```bash
  #!/bin/bash
  set -euo pipefail
  ```
  - Scripts must **fail-fast**: If any command or step fails, execution must halt immediately without leaving incomplete or unhandled states.
  - Do not suppress errors blindly (e.g. avoid unchecked `|| true` unless an operation is explicitly optional and its failure is safely handled).
- **Helper Sourcing**:
  ```bash
  source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"
  ```
- **Public Utilities & Helper Catalog (`scripts/_utils.sh`)**:
  Always reuse existing helpers from `scripts/_utils.sh` instead of reimplementing or calling raw tools directly:
  1. [`install_packages <pkg1> [pkg2...]`](../../../scripts/_utils.sh): Resolves packages via `packages.conf` across `apt`, `dnf`, and `pacman` and installs them idempotently.
  2. [`install_flatpak_app <app_id> [app_name]`](../../../scripts/_utils.sh): Ensures Flatpak/Flathub is configured and idempotently installs Flatpak applications.
  3. [`download_file <url> <dest>`](../../../scripts/_utils.sh): Downloads remote files to a destination path with automatic `curl` / `wget` fallback and fail-fast validation.
  4. [`fetch_url <url>`](../../../scripts/_utils.sh): Fetches remote content directly to stdout with `curl` / `wget` fallback.
  5. [`get_desktop_environment`](../../../scripts/_utils.sh): Detects current desktop environment (`gnome`, `plasma`, or `unknown`).
  6. [`get_root_filesystem`](../../../scripts/_utils.sh): Returns root filesystem type (e.g. `btrfs`, `ext4`, or `unknown`).
  7. [`get_shell_profile`](../../../scripts/_utils.sh): Resolves user configuration file path based on `$SHELL` (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).
- **Helper Function Conventions**:
  - Prefix script-private functions with `_` (e.g., `_configure_app`).
  - **No trivial one-line wrappers**: Do not create one-line functions that merely proxy a call if used only once. Inline the helper call directly.
  - **Desktop Environment Handling**: When a step depends on DE, check `get_desktop_environment`. If `unknown`, do not execute DE-specific actions.
- **Entrypoint & Execution Guard**:
  ```bash
  main() {
    # setup logic
  }

  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
  fi
  ```

#### B. Cross-Distro Package Mapping (`scripts/packages.conf`)

If package names differ across distributions or are unavailable in one:

- Add an entry to `scripts/packages.conf`:
  ```text
  GENERIC_NAME | APT_PACKAGE | DNF_PACKAGE | PACMAN_PACKAGE
  ```
- Use `-` when a package is unsupported on a specific distro.
- Keep strictly **alphabetical order** by generic name, preserve table column alignment, and ensure at least one space before and after every `|`.
- **Do not add** packages that share the exact same name across all three package managers (`apt`, `dnf`, `pacman`).

---

### Step 4: Automated Tests & Full Branch Coverage (Bats)

All code paths and conditional branches must be thoroughly tested:

1. **Unit Tests (`tests/unit/<feature>.bats`)**:
   - **100% Branch Coverage**: Test all `if`/`elif`/`else` branches, error cases, and distro branches (`apt`, `dnf`, `pacman`, unsupported distro).
   - Test Desktop Environment conditionals (`gnome`, `plasma`, `unknown`).
   - Mock external utilities and verify flag logic, package manager resolution, and fail-fast/exit-code behavior on errors.
2. **Integration Tests (`tests/integration/<feature>.bats`)**:
   - Test end-to-end execution inside clean containers across all supported distributions (**Debian 13**, **Fedora 44**, **Arch Linux**).
   - Validate idempotency: running the script a second time must succeed without errors or redundant modifications.

---

### Step 5: Orchestration, Makefile & Documentation

1. **Orchestrator (`main.sh`)**:
   - Add the script invocation into `main.sh` if it is part of the standard complete setup (`make all`).
2. **Makefile**:
   - Add a dedicated target (e.g., `<feature>:`) with inline help comment (`## Description`).
   - Maintain alphabetical order of targets (keeping `help` / `all` at the top and `clean` at the bottom).
3. **Documentation & Skill Synchronization**:
   - **`README.md`**: Add the new target in the "Quick start" section maintaining alphabetical order.
   - **`README-pt-br.md`**: Add the target in the "Como usar (rápido)" section matching the English README.
   - **`TODO.md`**: Mark corresponding task items as done `[x]` with script references.
   - **`.agents/skills/implement-feature/SKILL.md`**: **Mandatory Update**: If any new reusable helper or utility is added to `scripts/_utils.sh`, it must be immediately documented in this skill under _Step 3: Public Utilities & Helper Catalog_ with its signature and purpose.
   - **`AGENTS.md` & `CONTRIBUTING.md`**: Update common helper listings if applicable.

---

### Step 6: Mandatory Validation Execution (MANDATORY GATE)

At the conclusion of the implementation, the agent **MUST ALWAYS** run the unit and integration test suites specifically targeting the newly implemented feature:

1. **Unit Tests for the Feature**:
   ```bash
   ./tests/run-tests.sh --unit --filter=<feature>
   ```
   *Verify that all unit test cases for the feature pass.*

2. **Full Unit Test Suite (Regression Prevention)**:
   ```bash
   make test-unit
   ```
   *Ensure no regressions were introduced to other modules.*

3. **Integration Tests for the Feature (Multi-Distro Validation)**:
   ```bash
   ./tests/run-tests.sh --integration --filter=<feature>
   ```
   *Validate execution inside Debian, Fedora, and Arch Linux containers.*

4. **Linting (when shellcheck is available)**:
   ```bash
   shellcheck -x scripts/*.sh main.sh tests/*.sh 2>/dev/null || true
   ```

> [!IMPORTANT]
> Never execute `git commit` or `git push`. All git commits must be made exclusively by the user.
