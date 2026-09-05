# Specification: DBeaver Database GUI (`scripts/apps/setup-dbeaver.sh`)

## Purpose

Installs DBeaver Community Edition (CE) database management tool using the optimal distribution packaging strategy per operating system.

---

## Requirements

### Requirement: Distribution Packaging Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`)**: SHALL install the native distribution package `dbeaver`.
- **Debian (`debian`) & Fedora (`fedora`)**: SHALL install the official Flatpak package `io.dbeaver.DBeaverCommunity` via Flathub to ensure up-to-date releases and avoid repository bloat.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-dbeaver.sh` is executed
- **THEN** it SHALL call `install_packages dbeaver`
- **AND** it SHALL NOT attempt to install via Flatpak

#### Scenario: Running on Debian or Fedora

- **GIVEN** a Debian or Fedora system (`get_distro_id` returns `debian` or `fedora`)
- **WHEN** `scripts/apps/setup-dbeaver.sh` is executed
- **THEN** it SHALL invoke `install_flatpak_app io.dbeaver.DBeaverCommunity DBeaver`
- **AND** ensure Flatpak and Flathub are configured

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-dbeaver.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
