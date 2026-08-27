# Specification: Discord Client (`scripts/setup-discord.sh`)

## Purpose
Installs Discord desktop voice and text messaging client using the optimal distribution packaging strategy.

---

## Requirements

### Requirement: Distribution Packaging Strategy
The script SHALL select the installation provider based on the active package manager:
- **Arch Linux (`pacman`)**: SHALL install the native distribution package `discord`.
- **Debian (`apt`) & Fedora (`dnf`)**: SHALL install the official Flatpak package `com.discordapp.Discord` via Flathub (`install_flatpak_app`).

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system with `pacman`
- **WHEN** `scripts/setup-discord.sh` runs
- **THEN** it SHALL call `install_packages discord`
- **AND** it SHALL NOT invoke Flatpak

#### Scenario: Running on Debian or Fedora
- **GIVEN** a Debian or Fedora system with `apt` or `dnf`
- **WHEN** `scripts/setup-discord.sh` runs
- **THEN** it SHALL call `install_flatpak_app "com.discordapp.Discord" "Discord"`

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/setup-discord.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
