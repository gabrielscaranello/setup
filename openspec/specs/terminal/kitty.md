# Specification: Kitty Terminal Emulator (`scripts/setup-kitty.sh`)

## Purpose
Installs Kitty GPU-accelerated terminal emulator, desktop entries, icon integration, and PATH symlinks across distributions.

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL:
- **Fedora (`dnf`) & Arch Linux (`pacman`)**: Install `kitty` from distribution repositories.
- **Debian (`apt`)**: Query `https://sw.kovidgoyal.net/kitty/current-version.txt`, download and run the official standalone installer (`launch=n`) into `~/.local/kitty.app`, link binaries (`kitty`, `x-terminal-emulator`, `kitten`) to `~/.local/bin` and `/usr/local/bin`, and deploy desktop entries with full icon paths to `~/.local/share/applications`.

### Requirement: Idempotency & Version Verification
On Debian, if the local version in `~/.local/kitty.app/bin/kitty` matches the remote version, the installer execution SHALL be skipped and desktop integration re-verified.

#### Scenario: Running on Debian
- **GIVEN** a Debian system
- **WHEN** `scripts/setup-kitty.sh` runs
- **THEN** standalone Kitty is installed to `~/.local/kitty.app`, symlinked to PATH, and desktop entries configured
