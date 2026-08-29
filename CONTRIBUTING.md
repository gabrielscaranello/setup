# ✨ Contributing — Script pattern & expectations

Thank you for contributing!  
This guide explains the canonical pattern for scripts in `scripts/*.sh` and the expected workflow for PRs and validations.

## 🧭 Overview

This file is the reference for contributors, maintainers, and tools (linters, AIs). It defines script patterns, integration testing practices, and PR expectations.

## 📁 Repository Architecture & Layout

```
.
├── main.sh                        # Master CLI entrypoint forwarder (calls runners/main.sh)
├── Makefile                       # Convenience runner (make help, make test, etc.)
├── AGENTS.md                      # Authoritative AI instructions and rules
├── GEMINI.md                      # Pointer to AGENTS.md for Gemini/AI assistants
├── CONTRIBUTING.md                # Developer contribution guide & architecture
├── README.md / README-pt-br.md    # User documentation (EN / PT-BR)
├── runners/                       # Distro-specific orchestration pipelines
│   ├── _utils.sh                  # Runner helper (run_pipeline)
│   ├── arch.sh                    # Arch Linux setup pipeline
│   ├── debian.sh                  # Debian setup pipeline
│   ├── fedora.sh                  # Fedora setup pipeline
│   └── main.sh                    # Central CLI dispatcher and module runner
├── scripts/                       # Modular setup scripts (organized by domain)
│   ├── _utils.sh                  # Core abstraction (install_packages, etc.)
│   ├── packages.conf              # Declarative cross-distro package mappings
│   ├── apps/                      # Application setup scripts
│   ├── security/                  # Security setup scripts
│   ├── system/                    # System & OS setup scripts
│   ├── terminal/                  # Terminal tools & fonts setup scripts
│   └── toolchain/                 # Dev runtimes & toolchains
└── tests/                         # Test suite
    ├── docker/                    # Base Dockerfiles per distro
    ├── integration/               # Integration tests per domain/feature
    ├── unit/                      # Fast Bats unit tests per domain/feature
    └── run-tests.sh               # Master test orchestrator
```

## 📜 Script template and rules

- Start with shebang and strict mode:

```bash
#!/bin/bash
set -euo pipefail
```

- Source helpers (near the top):

```bash
source "scripts/_utils.sh" 2>/dev/null || true
```

- Private functions: prefix with `_` (e.g., `_install_node`). Public functions have no prefix (e.g., `install_packages` from `_utils.sh`). Keep functions small and idempotent.
- **Rule for One-Line Functions**: Do not create trivial one-line proxy functions if called in only one place. Inline the helper or command directly. Only keep one-line functions if reused across multiple locations.
- **Common Helpers**: Reuse abstractions from `scripts/_utils.sh` (`get_desktop_environment`, `get_root_filesystem`, `get_shell_profile`, `install_flatpak_app`, `download_file`, `fetch_url`).
- **Distribution Repository Helpers**: Reuse distro repository utilities for adding upstream or third-party repositories:
  - Debian (`scripts/system/debian/_repositories.sh`): `add_debian_backports_repo`, `add_debian_vscodium_repo`, `add_debian_mozilla_repo`.
  - Fedora (`scripts/system/fedora/_repositories.sh`): `add_fedora_docker_repo`, `add_fedora_vscodium_repo`.
- **Desktop Environment Handling**: Use `get_desktop_environment` to guard DE-specific steps. When the DE is not recognized (`unknown`), do nothing for DE-specific tasks.

- Entrypoint: expose `main()` and finalize with an execution guard:

```bash
main "$@"
```
or (when loaded in test suites):
```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- Target distributions:
  - **Debian 13 (Trixie)** (`apt`)
  - **Fedora 44** (`dnf`)
  - **Arch Linux** (`pacman` / Rolling)
- Branch by package manager via `_get_package_manager` from `_utils.sh` — do not hard-code.

- Use `/tmp/<package>` for temporary builds and ensure `make clean` removes artifacts.

## ✅ Idempotence and quality

- Scripts must be able to rerun without side effects.
- Clear logging and friendly error messages.
- Validate with:

```bash
shellcheck -x scripts/*.sh
```

## 📦 Package Mappings (`scripts/packages.conf`)

Cross-distribution package discrepancies must be registered in `scripts/packages.conf`:
- **Format**: `GENERIC_NAME | APT_PACKAGE | DNF_PACKAGE | PACMAN_PACKAGE`
- **Exclusivity**: Only add entries when package names differ across package managers or when unsupported (`-`) on a distro. Identical names are resolved automatically by fallback and should NOT be listed.
- **Formatting**: Must maintain alphabetical order by generic name, preserve table column alignment, and ensure at least one space before and after every `|` separator.

## 🔁 Script dependencies

if a script depends on another (e.g., neovim depends on nvm), document or install the dependency programmatically.

## 🧪 Integration Tests

Tests live under `tests/` and use [bats-core](https://github.com/bats-core/bats-core). Each test runs inside Docker to guarantee a clean, distro-specific environment across all supported distributions (Arch Linux, Debian, Fedora).

### Directory structure pattern

```
tests/
├── docker/                        # Generic base Dockerfiles (one per distro)
│   ├── <distro>.Dockerfile
│   └── ...
├── unit/                          # Fast unit tests (mocked, testing internal functions)
│   ├── <feature>.bats
│   └── ...
├── integration/                   # Cross-distro integration tests (E2E in containers)
│   ├── <feature>.bats
│   └── ...
└── run-tests.sh                   # Master test orchestrator
```

### Conventions & Guidelines

- **Base images** (`tests/docker/*.Dockerfile`): Install OS tools, bats-core, kcov, create a non-root user matching the host username (`$USER`) with passwordless `sudo`, and configure `/setup`.
- **Unit tests** (`tests/unit/<feature>.bats`):
  - Test pure logic, branching, error traps, and mock calls without triggering real installations or network requests.
  - Run quickly via `make test-unit`.
- **Integration tests** (`tests/integration/<feature>.bats`):
  - Use `setup_file()` to run the script once per test file in a clean container.
  - Shared across all supported distributions (Arch Linux, Debian, Fedora) to avoid duplication.
  - Implement tests (`@test`) verifying that required binaries, packages, configs, or outputs exist.
  - Always include an idempotency check (running the script a second time should exit with status 0).
- **Running tests**:
  - Run all tests: `make test` (or `./tests/run-tests.sh`)
  - Run unit tests only: `make test-unit` (or `./tests/run-tests.sh --unit`)
  - Run integration tests only: `make test-integration` (or `./tests/run-tests.sh --integration`)
  - Target a specific distro: `make test DISTRO=debian` (or `./tests/run-tests.sh --distro=debian`)
  - Filter specific tests: `make test FILTER=nvm` (or `./tests/run-tests.sh --filter=nvm`)
- **Code coverage**: Run `make test-coverage` (or `./tests/run-tests.sh --coverage`) to generate unified code coverage reports in `coverage/` using `kcov`.

## 🧾 Documentation and Pull Requests

Changes that add or modify scripts MUST include:

- The scripts/file added
- Corresponding integration tests under `tests/<script>/`
- A Makefile target when useful (e.g., `make neovim`)
- Update to main.sh if the `make all` flow should run it
- ShellCheck output in CI or PR body

Minor edits (typos/formatting) may omit AGENTS.md — document the reason in the PR.

## 📋 PR checklist (use as template)

- [ ] Code added to scripts/
- [ ] scripts/packages.conf updated (if cross-distro package mappings needed)
- [ ] Makefile updated (when applicable)
- [ ] Task checked off in TODO.md (when applicable)
- [ ] Makefile target added (when applicable)
- [ ] README.md and README-pt-br.md updated (when applicable)
- [ ] AGENTS.md updated (when applicable)
- [ ] shellcheck OK
- [ ] Basic manual test documented in PR

## 🧩 Quick script example

```bash
#!/bin/bash
set -euo pipefail
source "scripts/_utils.sh" 2>/dev/null || true

_do_something() {
  echo "Installing foo..."
  install_packages foo
}

main() {
  _do_something
}

main "$@"
```

## ❓ Questions

Open an issue or tag reviewers when the change affects orchestration or public behavior.

---

Made with ❤️ — thank you for helping keep this project consistent!
