# Specification: Lazydocker TUI (`scripts/terminal/setup-lazydocker.sh`)

## Purpose

Installs Lazydocker terminal UI for Docker container management.

---

## Requirements

### Requirement: Distribution Installation Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`)**: Install `lazydocker` from distribution repositories via `install_packages lazydocker`.
- **Debian (`debian`) & Fedora (`fedora`)**: Query the GitHub API (`jesseduffield/lazydocker`) for the latest release, detect CPU architecture (`x86_64`, `arm64`, `x86`), download and extract tarball to `/usr/local/bin/lazydocker`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Idempotency

On Debian/Fedora, if `lazydocker --version` matches the latest GitHub release, download and extraction SHALL be skipped.

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/terminal/setup-lazydocker.sh` runs
- **THEN** `install_packages lazydocker` is called

#### Scenario: Running on Fedora or Debian

- **GIVEN** a Fedora or Debian system (`get_distro_id` returns `fedora` or `debian`)
- **WHEN** `scripts/terminal/setup-lazydocker.sh` runs
- **THEN** latest binary release is downloaded and installed to `/usr/local/bin/lazydocker`

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/terminal/setup-lazydocker.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
