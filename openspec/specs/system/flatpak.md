# Specification: Flatpak Runtime & Flathub Configuration (`scripts/setup-flatpak.sh`)

## Purpose
Idempotently installs the Flatpak package manager integration and enables the primary Flathub remote repository across all supported distributions.

---

## Requirements

### Requirement: Flatpak Package Installation
The script SHALL install `flatpak` using the native package manager for Debian, Fedora, or Arch Linux.

#### Scenario: Flatpak not installed
- **GIVEN** a clean system without Flatpak
- **WHEN** `scripts/setup-flatpak.sh` is executed
- **THEN** `flatpak` binary SHALL be installed and available in `PATH`

### Requirement: Flathub Remote Management
The script SHALL add the official Flathub remote if not already present.

#### Scenario: Adding Flathub remote
- **GIVEN** Flatpak is installed without `flathub` remote configured
- **WHEN** `scripts/setup-flatpak.sh` runs
- **THEN** `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo` SHALL be executed
- **AND** subsequent runs SHALL remain idempotent without duplicating the remote
