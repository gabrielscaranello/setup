# Specification: MongoDB Compass (`scripts/apps/setup-mongodb-compass.sh`)

## Purpose

Installs the official MongoDB Compass GUI across all supported distributions (Arch Linux, Debian, Fedora) using the official Flatpak package (`mongodb.Compass`) from Flathub to guarantee compatibility and seamless cross-platform updates.

---

## Requirements

### Requirement: Uniform Flatpak Packaging Strategy

The script SHALL install MongoDB Compass via Flatpak across all supported distributions:

- **All Supported Distros (`apt`, `dnf`, `pacman`)**: SHALL invoke `install_flatpak_app "mongodb.Compass" "MongoDB Compass"`.
- **Unsupported Distros**: SHALL exit with code 1 and write an error message to `stderr`.

#### Scenario: Running on Debian, Fedora, or Arch Linux

- **GIVEN** a supported distribution running `apt`, `dnf`, or `pacman`
- **WHEN** `scripts/apps/setup-mongodb-compass.sh` is executed
- **THEN** it SHALL call `install_flatpak_app "mongodb.Compass" "MongoDB Compass"`
- **AND** ensure Flatpak runtime and Flathub remote are configured

#### Scenario: Application is already installed

- **GIVEN** `mongodb.Compass` is already installed
- **WHEN** `scripts/apps/setup-mongodb-compass.sh` is executed
- **THEN** it SHALL exit with code 0 idempotently without reinstalling

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/apps/setup-mongodb-compass.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
