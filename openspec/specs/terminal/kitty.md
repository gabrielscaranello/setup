# Specification: Kitty Terminal Emulator (`scripts/terminal/setup-kitty.sh`)

## Purpose
Installs Kitty GPU-accelerated terminal emulator, desktop entries, icon integration, and PATH symlinks across distributions.

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):
- **Fedora (`fedora`) & Arch Linux (`arch`)**: Install `kitty` from distribution repositories via `install_packages kitty`.
- **Debian (`debian`)**: Query `https://sw.kovidgoyal.net/kitty/current-version.txt`, download and run the official standalone installer (`launch=n`) into `~/.local/kitty.app`, link binaries (`kitty`, `x-terminal-emulator`, `kitten`) to `~/.local/bin` and `/usr/local/bin`, and deploy desktop entries with full icon paths to `~/.local/share/applications`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Idempotency & Version Verification
On Debian, if the local version in `~/.local/kitty.app/bin/kitty` matches the remote version, the installer execution SHALL be skipped and desktop integration re-verified.

#### Scenario: Running on Fedora or Arch Linux
- **GIVEN** a Fedora or Arch Linux system (`get_distro_id` returns `fedora` or `arch`)
- **WHEN** `scripts/terminal/setup-kitty.sh` runs
- **THEN** `kitty` package is installed from distribution repositories

#### Scenario: Running on Debian
- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/terminal/setup-kitty.sh` runs
- **THEN** standalone Kitty is installed to `~/.local/kitty.app`, symlinked to PATH, and desktop entries configured

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/terminal/setup-kitty.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
