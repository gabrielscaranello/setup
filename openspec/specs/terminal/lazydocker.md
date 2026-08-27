# Specification: Lazydocker TUI (`scripts/setup-lazydocker.sh`)

## Purpose
Installs Lazydocker terminal UI for Docker container management.

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL:
- **Arch Linux (`pacman`)**: Install `lazydocker` from distribution repositories via `install_packages`.
- **Debian (`apt`) & Fedora (`dnf`)**: Query the GitHub API (`jesseduffield/lazydocker`) for the latest release, detect CPU architecture (`x86_64`, `arm64`, `x86`), download and extract tarball to `/usr/local/bin/lazydocker`.

### Requirement: Idempotency
On Debian/Fedora, if `lazydocker --version` matches the latest GitHub release, download and extraction SHALL be skipped.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system
- **WHEN** `scripts/setup-lazydocker.sh` runs
- **THEN** `install_packages lazydocker` is called

#### Scenario: Running on Fedora or Debian
- **GIVEN** a Fedora or Debian system
- **WHEN** `scripts/setup-lazydocker.sh` runs
- **THEN** latest binary release is downloaded and installed to `/usr/local/bin/lazydocker`
