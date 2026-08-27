# Specification: Lazygit TUI (`scripts/setup-lazygit.sh`)

## Purpose
Installs Lazygit terminal UI for Git, provisioning native packages on Arch Linux and fetching the latest upstream GitHub release binary for Debian and Fedora with version checking and idempotent installation.

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL determine the installation mechanism based on the active package manager:
- **Arch Linux (`pacman`)**: SHALL install `lazygit` directly from official repositories using `install_packages lazygit`.
- **Debian (`apt`) & Fedora (`dnf`)**: SHALL ensure utility packages (`curl`, `wget`, `tar`) are present, query the GitHub API (`https://api.github.com/repos/jesseduffield/lazygit/releases/latest`) to discover the latest tag name, download `lazygit_<version>_Linux_x86_64.tar.gz` to `/tmp`, extract to `/tmp/lazygit-extract`, install the binary to `/usr/local/bin/lazygit` using `sudo install`, and clean up temporary files.

---

### Requirement: Version Verification & Idempotency
On Debian and Fedora, the script SHALL check if an installed `lazygit` binary exists (`command -v lazygit` or `/usr/local/bin/lazygit`) and parse its version (`lazygit --version | grep -Po 'version=\K[^,]*'`).
- If the locally installed version matches the latest remote release tag from GitHub, download, extraction, and installation steps SHALL be skipped.
- If no local binary exists or the version differs, the latest binary release SHALL be downloaded and installed.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system with `pacman`
- **WHEN** `scripts/setup-lazygit.sh` is executed
- **THEN** it SHALL call `install_packages lazygit`
- **AND** it SHALL NOT attempt to query the GitHub API or download binaries manually

#### Scenario: Running on Debian or Fedora (Fresh Installation)
- **GIVEN** a Debian or Fedora system without `lazygit` installed
- **WHEN** `scripts/setup-lazygit.sh` is executed
- **THEN** it SHALL query GitHub API for the latest version tag
- **AND** download, extract, and install `/usr/local/bin/lazygit`
- **AND** remove temporary files from `/tmp`

#### Scenario: Running on Debian or Fedora when already up to date
- **GIVEN** a Debian or Fedora system with the latest `lazygit` version already present
- **WHEN** `scripts/setup-lazygit.sh` is executed
- **THEN** it SHALL output a notice indicating lazygit is up to date and skip the download/install steps

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/setup-lazygit.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
