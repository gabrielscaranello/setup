# Specification: Obsidian Knowledge Base (`scripts/apps/setup-obsidian.sh`)

## Purpose

Installs Obsidian note-taking and knowledge base application across supported distributions (Arch Linux, Debian, Fedora), using distribution packages directly on Arch Linux and Flatpak from Flathub on Debian and Fedora.

---

## Requirements

### Requirement: Distribution Packaging Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`)**: SHALL install `obsidian` directly from official repositories via `install_packages obsidian`.
- **Debian (`debian`) & Fedora (`fedora`)**: SHALL install the official Flatpak package `md.obsidian.Obsidian` via Flathub (`install_flatpak_app "md.obsidian.Obsidian" "Obsidian"`).
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-obsidian.sh` is executed
- **THEN** it SHALL call `install_packages obsidian`
- **AND** it SHALL NOT attempt to install via Flatpak

#### Scenario: Running on Debian or Fedora

- **GIVEN** a Debian or Fedora system (`get_distro_id` returns `debian` or `fedora`)
- **WHEN** `scripts/apps/setup-obsidian.sh` is executed
- **THEN** it SHALL invoke `install_flatpak_app "md.obsidian.Obsidian" "Obsidian"`
- **AND** ensure Flatpak and Flathub are configured

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-obsidian.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
