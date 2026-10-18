# Specification: Discord Client (`scripts/apps/setup-discord.sh`)

## Purpose

Installs Discord desktop voice and text messaging client using the optimal distribution packaging strategy.

---

## Requirements

### Requirement: Distribution Packaging Strategy

The script SHALL select the installation provider based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`) & openSUSE Tumbleweed (`opensuse-tumbleweed`)**: SHALL install the native distribution package `discord`.
- **Debian (`debian`), Fedora (`fedora`), & openSUSE Leap (`opensuse-leap`, `opensuse`)**: SHALL install the official Flatpak package `com.discordapp.Discord` via Flathub (`install_flatpak_app`).
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Arch Linux or openSUSE Tumbleweed

- **GIVEN** an Arch Linux or openSUSE Tumbleweed system (`get_distro_id` returns `arch` or `opensuse-tumbleweed`)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL call `install_packages discord`
- **AND** it SHALL NOT invoke Flatpak

#### Scenario: Running on Debian, Fedora, or openSUSE Leap

- **GIVEN** a Debian, Fedora, or openSUSE Leap system (`get_distro_id` returns `debian`, `fedora`, `opensuse`, or `opensuse-leap`)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL call `install_flatpak_app "com.discordapp.Discord" "Discord"`

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-discord.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
