# Specification: ONLYOFFICE Desktop Editors (`scripts/apps/setup-onlyoffice.sh`)

## Purpose

Installs ONLYOFFICE Desktop Editors across all supported distributions (Arch Linux, Debian, Fedora) using the official Flatpak package (`org.onlyoffice.desktopeditors`) from Flathub to guarantee consistent office suite functionality, font rendering, and seamless updates.

---

## Requirements

### Requirement: Uniform Flatpak Packaging Strategy

The script SHALL install ONLYOFFICE Desktop Editors via Flatpak across all supported distributions:

- **All Supported Distros (`debian`, `fedora`, `arch`, `opensuse-leap`, `opensuse-tumbleweed`, `opensuse`)**: SHALL invoke `install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

#### Scenario: Running on a supported distribution

- **GIVEN** a supported distribution (`debian`, `fedora`, `arch`, or `opensuse`)
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL call `install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"`
- **AND** ensure Flatpak runtime and Flathub remote are configured

#### Scenario: Application is already installed

- **GIVEN** `org.onlyoffice.desktopeditors` is already installed
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL exit with code 0 idempotently without reinstalling

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-onlyoffice.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
