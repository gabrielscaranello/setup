# Specification: Developer & System Fonts (`scripts/setup-fonts.sh`)

## Purpose
Installs core system font packages (`fonts-liberation`, `fonts-roboto`, `fonts-carlito`, `fonts-noto`, `fonts-noto-color-emoji`) and provisions JetBrains Mono Nerd Font from upstream releases or native repositories.

---

## Requirements

### Requirement: System Fonts Installation
The script SHALL install base system fonts (`fonts-liberation`, `fonts-roboto`, `fonts-carlito`, `fonts-noto`, `fonts-noto-color-emoji`) across all distributions via `install_packages`.

### Requirement: JetBrains Mono Nerd Font Strategy
The script SHALL:
- **Arch Linux (`pacman`)**: Install `fonts-jetbrains-mono-nerd` via package manager.
- **Debian (`apt`) & Fedora (`dnf`)**: Download `JetBrainsMono.zip` from GitHub releases (`ryanoasis/nerd-fonts`), extract regular, bold, and italic TTF fonts into `~/.fonts`, clean up temporary files, and refresh font cache via `fc-cache -f`.
- **Idempotency**: Skip upstream font download if `~/.fonts/JetBrainsMonoNerdFont*.ttf` exists or `fc-list` detects `JetBrainsMono Nerd Font`.

#### Scenario: Running on Debian or Fedora
- **GIVEN** a Debian or Fedora system without Nerd Fonts
- **WHEN** `scripts/setup-fonts.sh` runs
- **THEN** system fonts are installed, JetBrainsMono archive is unpacked to `~/.fonts`, and `fc-cache` is refreshed

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system
- **WHEN** `scripts/setup-fonts.sh` runs
- **THEN** `fonts-jetbrains-mono-nerd` is installed directly from repository
