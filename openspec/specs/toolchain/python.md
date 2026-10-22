# Specification: Python Runtime & Package Tools (`scripts/toolchain/setup-python.sh`)

## Purpose

Installs Python 3 (`python3`), `pip` (`python-pip`), and virtual environment tools (`python-venv`) via native distribution repositories across all supported distributions.

---

## Requirements

### Requirement: Distribution Validation & Native Package Installation

The script SHALL validate that the target distribution is supported via `require_supported_distro` and install `python3`, `python-pip`, and `python-venv` via `install_packages`:

- **Debian (`debian`)**: Resolves to `python3`, `python3-pip`, and `python3-venv`.
- **Fedora (`fedora`)**: Resolves to `python3` and `python3-pip` (`venv` is bundled in `python3`).
- **Arch Linux (`arch`)**: Resolves to `python` and `python-pip` (`venv` is bundled in `python`).
- **openSUSE (`opensuse-leap`, `opensuse-tumbleweed`, `opensuse`)**: Resolves to `python3` and `python3-pip`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

#### Scenario: Running on a supported distribution

- **GIVEN** a supported distribution (`get_distro_id` returns `debian`, `fedora`, `arch`, `opensuse-leap`, `opensuse-tumbleweed`, or `opensuse`)
- **WHEN** `scripts/toolchain/setup-python.sh` runs
- **THEN** `python3`, `python-pip`, and `python-venv` SHALL be installed via `install_packages`
- **AND** `python3` and `pip3` binaries SHALL be available in `PATH`

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution (`require_supported_distro` returns 1)
- **WHEN** `scripts/toolchain/setup-python.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`

#### Scenario: Re-running setup-python (Idempotency)

- **GIVEN** Python 3 and `pip` are already installed
- **WHEN** `scripts/toolchain/setup-python.sh` is re-run
- **THEN** package installation SHALL succeed idempotently with exit code 0
