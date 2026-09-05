# Specification: Discord Client (`scripts/apps/setup-discord.sh`)

## Purpose
Installs Discord desktop voice and text messaging client using the optimal distribution packaging strategy.

---

## Requirements

### Requirement: Distribution Packaging Strategy
The script SHALL select the installation provider based on the target distribution (`get_distro_id`):
- **Arch Linux (`arch`)**: SHALL install the native distribution package `discord`.
- **Debian (`debian`) & Fedora (`fedora`)**: SHALL install the official Flatpak package `com.discordapp.Discord` via Flathub (`install_flatpak_app`).
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL call `install_packages discord`
- **AND** it SHALL NOT invoke Flatpak

#### Scenario: Running on Debian or Fedora
- **GIVEN** a Debian or Fedora system (`get_distro_id` returns `debian` or `fedora`)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL call `install_flatpak_app "com.discordapp.Discord" "Discord"`

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
