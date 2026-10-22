# Specification: GitHub CLI (`scripts/toolchain/setup-gh.sh`)

## Purpose

Installs the official GitHub CLI (`gh`) via native distribution repositories (`github-cli` generic package mapping) exclusively when running inside a Windows Subsystem for Linux (WSL) environment.

---

## Requirements

### Requirement: WSL-Exclusive Execution Guard

The script SHALL inspect the execution environment via `is_wsl`. When not running inside WSL, it SHALL print an informative message and exit gracefully with code 0 without installing any packages.

### Requirement: Distribution Validation & Native Package Installation

When running inside WSL, the script SHALL validate that the target distribution is supported via `require_supported_distro` and install `github-cli` via `install_packages github-cli` (`gh` on Debian, Fedora, and openSUSE; `github-cli` on Arch Linux).

#### Scenario: Running outside WSL (Bare Metal or Standard Container)

- **GIVEN** `is_wsl` returns 1
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** it SHALL output a message indicating GitHub CLI setup is restricted to WSL and exit with code 0

#### Scenario: Running inside WSL on a supported distribution

- **GIVEN** `is_wsl` returns 0 and `require_supported_distro` succeeds (`debian`, `fedora`, `arch`, `opensuse-leap`, `opensuse-tumbleweed`, or `opensuse`)
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** `github-cli` SHALL be installed via `install_packages github-cli`
- **AND** the `gh` binary SHALL be available in `PATH`

#### Scenario: Running inside WSL on an unsupported distribution

- **GIVEN** `is_wsl` returns 0 and `require_supported_distro` returns 1
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`

#### Scenario: Re-running setup-gh inside WSL (Idempotency)

- **GIVEN** `gh` is already installed inside WSL
- **WHEN** `scripts/toolchain/setup-gh.sh` is re-run
- **THEN** package installation SHALL succeed idempotently with exit code 0
