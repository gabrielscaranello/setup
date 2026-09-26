# Specification: GIMP Image Editor (`scripts/apps/setup-gimp.sh`)

## Purpose

Installs the GIMP GNU Image Manipulation Program across supported distributions (Arch Linux, Fedora, Debian, LMDE), using official distribution repository packages on Fedora and Arch Linux, and Flatpak from Flathub on Debian and LMDE.

---

## Requirements

### Requirement: Distribution Packaging Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`) & Fedora (`fedora`)**: SHALL install `gimp` directly from official repositories via `install_packages gimp`.
- **Debian (`debian`) & LMDE (`lmde`)**: SHALL install the official Flatpak package `org.gimp.GIMP` via Flathub (`install_flatpak_app "org.gimp.GIMP" "GIMP"`).
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-gimp.sh` is executed
- **THEN** it SHALL call `install_packages gimp`
- **AND** it SHALL NOT attempt to install via Flatpak

#### Scenario: Running on Fedora

- **GIVEN** a Fedora system (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/apps/setup-gimp.sh` is executed
- **THEN** it SHALL call `install_packages gimp`
- **AND** it SHALL NOT attempt to install via Flatpak

#### Scenario: Running on Debian or LMDE

- **GIVEN** a Debian or LMDE system (`get_distro_id` returns `debian` or `lmde`)
- **WHEN** `scripts/apps/setup-gimp.sh` is executed
- **THEN** it SHALL invoke `install_flatpak_app "org.gimp.GIMP" "GIMP"`
- **AND** ensure Flatpak and Flathub are configured

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-gimp.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
