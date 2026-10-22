# Specification: GitHub CLI (`scripts/toolchain/setup-gh.sh`)

## Purpose

Installs the official GitHub CLI (`gh`) via the native Debian repository exclusively when running inside a Debian Windows Subsystem for Linux (WSL) environment.

---

## Requirements

### Requirement: WSL-Exclusive Execution Guard

The script SHALL inspect the execution environment via `is_wsl`. When not running inside WSL, it SHALL print an informative message and exit gracefully with code 0 without installing any packages.

### Requirement: Debian Distribution Validation & Native Package Installation

When running inside WSL, the script SHALL validate that the target distribution is `debian` via `is_distro "debian"` and install `gh` via `install_packages gh`. If invoked inside WSL on any other distribution, it SHALL print an error message to `stderr` and exit with code 1.

#### Scenario: Running outside WSL (Bare Metal or Standard Container)

- **GIVEN** `is_wsl` returns 1
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** it SHALL output a message indicating GitHub CLI setup is restricted to WSL and exit with code 0

#### Scenario: Running inside WSL on Debian

- **GIVEN** `is_wsl` returns 0 and `is_distro "debian"` returns 0
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** `gh` SHALL be installed via `install_packages gh`
- **AND** the `gh` binary SHALL be available in `PATH`

#### Scenario: Running inside WSL on a non-Debian distribution

- **GIVEN** `is_wsl` returns 0 and `is_distro "debian"` returns 1
- **WHEN** `scripts/toolchain/setup-gh.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`

#### Scenario: Re-running setup-gh inside WSL on Debian (Idempotency)

- **GIVEN** `gh` is already installed inside Debian WSL
- **WHEN** `scripts/toolchain/setup-gh.sh` is re-run
- **THEN** package installation SHALL succeed idempotently with exit code 0
