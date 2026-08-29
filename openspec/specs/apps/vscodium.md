# Specification: VSCodium (`scripts/apps/setup-vscodium.sh`)

## Purpose
Installs the VSCodium (or Code - OSS on Arch) open-source editor across supported distributions (Arch Linux, Debian, Fedora), configuring official upstream repositories with GPG verification on Debian and Fedora, and using repository packages directly on Arch Linux.

---

## Requirements

### Requirement: Distribution Packaging & Repository Strategy
The script SHALL determine the installation mechanism based on the active package manager:
- **Arch Linux (`pacman`)**: SHALL install `code` directly from distribution repositories via `install_packages code`.
- **Debian (`apt`)**: SHALL configure the VSCodium upstream APT repository (importing GPG key to `/usr/share/keyrings/vscodium-archive-keyring.gpg` or `/etc/apt/keyrings/vscodium-archive-keyring.gpg`, adding `/etc/apt/sources.list.d/vscodium.sources`), run `apt update`, and install package `codium` via `install_packages codium`.
- **Fedora (`dnf`)**: SHALL configure the VSCodium upstream YUM/DNF repository at `/etc/yum.repos.d/vscodium.repo` with GPG verification (`https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg`) and install package `codium` via `install_packages codium`.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system with `pacman`
- **WHEN** `scripts/apps/setup-vscodium.sh` is executed
- **THEN** it SHALL call `install_packages code`
- **AND** it SHALL NOT attempt to add third-party APT or DNF repositories

#### Scenario: Running on Debian
- **GIVEN** a Debian system with `apt`
- **WHEN** `scripts/apps/setup-vscodium.sh` is executed
- **THEN** it SHALL ensure `wget` or `curl` and `gpg` are present
- **AND** it SHALL download and dearmor the VSCodium GPG key to `/usr/share/keyrings/vscodium-archive-keyring.gpg` (or `/etc/apt/keyrings/vscodium-archive-keyring.gpg`)
- **AND** it SHALL write the deb822 source file `/etc/apt/sources.list.d/vscodium.sources` (pointing to `https://download.vscodium.com/debs`)
- **AND** it SHALL update APT index and install `codium` via `install_packages codium`
- **AND** subsequent executions SHALL skip repository setup idempotently if already configured

#### Scenario: Running on Fedora
- **GIVEN** a Fedora system with `dnf`
- **WHEN** `scripts/apps/setup-vscodium.sh` is executed
- **THEN** it SHALL write `/etc/yum.repos.d/vscodium.repo` with baseurl `https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/` and GPG key `https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg`
- **AND** it SHALL install `codium` via `install_packages codium`
- **AND** subsequent executions SHALL skip repository setup idempotently if the `.repo` file already exists

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/apps/setup-vscodium.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
