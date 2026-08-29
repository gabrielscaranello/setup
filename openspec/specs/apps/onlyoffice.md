# Specification: ONLYOFFICE Desktop Editors (`scripts/apps/setup-onlyoffice.sh`)

## Purpose

Installs ONLYOFFICE Desktop Editors across all supported distributions (Arch Linux, Debian, Fedora) using the official Flatpak package (`org.onlyoffice.desktopeditors`) from Flathub to guarantee consistent office suite functionality, font rendering, and seamless updates.

---

## Requirements

### Requirement: Uniform Flatpak Packaging Strategy

The script SHALL install ONLYOFFICE Desktop Editors via Flatpak across all supported distributions:

- **All Supported Distros (`apt`, `dnf`, `pacman`)**: SHALL invoke `install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"`.
- **Unsupported Distros**: SHALL exit with code 1 and write an error message to `stderr`.

#### Scenario: Running on Debian, Fedora, or Arch Linux

- **GIVEN** a supported distribution running `apt`, `dnf`, or `pacman`
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL call `install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"`
- **AND** ensure Flatpak runtime and Flathub remote are configured

#### Scenario: Application is already installed

- **GIVEN** `org.onlyoffice.desktopeditors` is already installed
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL exit with code 0 idempotently without reinstalling

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
