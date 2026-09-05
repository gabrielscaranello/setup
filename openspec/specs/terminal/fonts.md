# Specification: Developer & System Fonts (`scripts/terminal/setup-fonts.sh`)

## Purpose

Installs core system font packages (`fonts-liberation`, `fonts-roboto`, `fonts-carlito`, `fonts-noto`, `fonts-noto-color-emoji`) and provisions JetBrains Mono Nerd Font from upstream releases or native repositories.

---

## Requirements

### Requirement: System Fonts Installation

The script SHALL install base system fonts (`fonts-liberation`, `fonts-roboto`, `fonts-carlito`, `fonts-noto`, `fonts-noto-color-emoji`) across all distributions via `install_packages`.

### Requirement: JetBrains Mono Nerd Font Strategy

The script SHALL determine the font installation strategy based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`)**: Install `fonts-jetbrains-mono-nerd` via package manager (`install_packages`).
- **Debian (`debian`) & Fedora (`fedora`)**: Download `JetBrainsMono.zip` from GitHub releases (`ryanoasis/nerd-fonts`), extract regular, bold, and italic TTF fonts into `~/.fonts`, clean up temporary files, and refresh font cache via `fc-cache -f`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.
- **Idempotency**: Skip upstream font download if `~/.fonts/JetBrainsMonoNerdFont*.ttf` exists or `fc-list` detects `JetBrainsMono Nerd Font`.

#### Scenario: Running on Debian or Fedora

- **GIVEN** a Debian or Fedora system without Nerd Fonts (`get_distro_id` returns `debian` or `fedora`)
- **WHEN** `scripts/terminal/setup-fonts.sh` runs
- **THEN** system fonts are installed, JetBrainsMono archive is unpacked to `~/.fonts`, and `fc-cache` is refreshed

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/terminal/setup-fonts.sh` runs
- **THEN** `fonts-jetbrains-mono-nerd` is installed directly from repository

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/terminal/setup-fonts.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
