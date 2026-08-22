# ✨ Contributing — Script pattern & expectations

Thank you for contributing!  
This guide explains the canonical pattern for scripts in `scripts/*.sh` and the expected workflow for PRs and validations.

## 🧭 Overview

This file is the reference for contributors, maintainers, and tools (linters, AIs). It defines script patterns, integration testing practices, and PR expectations.

## 📁 Repository Architecture & Layout

```
.
├── main.sh                        # Master orchestrator script (make all)
├── Makefile                       # Convenience runner (make help, make test, etc.)
├── AGENTS.md                      # AI instructions and rules
├── CONTRIBUTING.md                # Developer contribution guide & architecture
├── README.md / README-pt-br.md    # User documentation (EN / PT-BR)
├── scripts/                       # Modular setup scripts
│   ├── _utils.sh                  # Core abstraction (install_packages, etc.)
│   └── setup-<feature>.sh         # Individual setup scripts (e.g. setup-neovim.sh, setup-nvm.sh)
└── tests/                         # Integration test suite
    ├── docker/                    # Base Dockerfiles per distro
    ├── <feature>/                 # Integration tests per feature
    └── run-tests.sh               # Master test runner
```

## 📜 Script template and rules

- Start with shebang and strict mode:

```bash
#!/bin/bash
set -euo pipefail
```

- Source helpers (near the top):

```bash
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"
```

- Private functions: prefix with `_` (e.g., `_install_node`). Public functions have no prefix (e.g., `install_packages` from `_utils.sh`). Keep functions small and idempotent.

- Entrypoint: expose `main()` and finalize with:

```bash
main "$@"
```

- Branch by package manager via `_get_package_manager` from `_utils.sh` — do not hard-code.

- Use `/tmp/<package>` for temporary builds and ensure `make clean` removes artifacts.

## ✅ Idempotence and quality

- Scripts must be able to rerun without side effects.
- Clear logging and friendly error messages.
- Validate with:

```bash
shellcheck -x scripts/*.sh
```

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
├── <feature-or-script>/           # Integration tests for a given script
│   ├── <script>-<distro>.bats
│   └── <distro>.Dockerfile        # (Optional) Custom image extending base
└── run-tests.sh                   # Master test orchestrator
```

### Conventions & Guidelines

- **Base images** (`tests/docker/*.Dockerfile`): Install OS tools, bats-core, kcov, create the `gabriel` non-root user with passwordless `sudo`, and copy the project into `/setup`.
- **Test files** (`tests/<script>/<script>-<distro>.bats`):
  - Use `setup_file()` to run the script once per test file.
  - Implement tests (`@test`) verifying that required binaries, packages, configs, or outputs exist.
  - Always include an idempotency check (running the script a second time should exit with status 0).
- **Test-specific Dockerfiles**: If a specific test requires extra setup, extend the base image with a custom `Dockerfile` in `tests/<script>/` (e.g. `tests/<script>/<distro>.Dockerfile`).
- **Running tests**: Run `make test` (or `./tests/run-tests.sh`) to build all images and execute the entire test suite.
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
- [ ] Makefile updated (when applicable)
- [ ] main.sh updated (when applicable)
- [ ] README.md and README-pt-br.md updated (when applicable)
- [ ] AGENTS.md updated (when applicable)
- [ ] shellcheck OK
- [ ] Basic manual test documented in PR

## 🧩 Quick script example

```bash
#!/bin/bash
set -euo pipefail
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

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
