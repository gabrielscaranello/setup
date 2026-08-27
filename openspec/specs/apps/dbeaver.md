# Specification: DBeaver Database GUI (`scripts/setup-dbeaver.sh`)

## Purpose
Installs DBeaver Community Edition (CE) database management tool using the optimal distribution packaging strategy per operating system.

---

## Requirements

### Requirement: Distribution Packaging Strategy
The script SHALL determine the installation mechanism based on the active package manager:
- **Arch Linux (`pacman`)**: SHALL install the native distribution package `dbeaver`.
- **Debian (`apt`) & Fedora (`dnf`)**: SHALL install the official Flatpak package `io.dbeaver.DBeaverCommunity` via Flathub to ensure up-to-date releases and avoid repository bloat.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system with `pacman`
- **WHEN** `scripts/setup-dbeaver.sh` is executed
- **THEN** it SHALL call `install_packages dbeaver`
- **AND** it SHALL NOT attempt to install via Flatpak

#### Scenario: Running on Debian or Fedora
- **GIVEN** a Debian or Fedora system with `apt` or `dnf`
- **WHEN** `scripts/setup-dbeaver.sh` is executed
- **THEN** it SHALL invoke `install_flatpak_app io.dbeaver.DBeaverCommunity DBeaver`
- **AND** ensure Flatpak and Flathub are configured

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/setup-dbeaver.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
