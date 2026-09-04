# Specification: Debian Repositories Configuration (`scripts/system/debian/_repositories.sh`)

## Purpose

Provides helper functions to detect Debian version codenames and idempotently configure official Debian Backports and third-party upstream repositories (such as Mozilla and VSCodium).

---

## Requirements

### Requirement: Codename Detection

The helper SHALL resolve the Debian release codename from `/etc/os-release` (`DEBIAN_CODENAME` or `VERSION_CODENAME`) or `lsb_release`, defaulting to `bookworm` if undetected.

### Requirement: Idempotent Backports Configuration

The function `add_debian_backports_repo` SHALL check `/etc/apt/sources.list` and `/etc/apt/sources.list.d/` for existing backports configurations before creating `/etc/apt/sources.list.d/backports.list`.

#### Scenario: Backports already present

- **GIVEN** APT sources already contain `<codename>-backports`
- **WHEN** `add_debian_backports_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Adding Backports

- **GIVEN** no backports repository exists
- **WHEN** `add_debian_backports_repo` is called
- **THEN** `/etc/apt/sources.list.d/backports.list` SHALL be written with `main contrib non-free non-free-firmware` components
- **AND** `sudo apt update -qq` SHALL be executed

### Requirement: Idempotent VSCodium APT Repository Configuration

The function `add_debian_vscodium_repo` SHALL configure the official VSCodium APT repository deb822 source and GPG keyring if not already present.

#### Scenario: VSCodium repository already configured

- **GIVEN** `/etc/apt/sources.list.d/vscodium.sources` and `/usr/share/keyrings/vscodium-archive-keyring.gpg` exist
- **WHEN** `add_debian_vscodium_repo` is called
- **THEN** it SHALL output a skip message and return 0 without repeating downloads

#### Scenario: Adding VSCodium repository

- **GIVEN** VSCodium repository is not yet configured
- **WHEN** `add_debian_vscodium_repo` is called
- **THEN** it SHALL download the GPG key from `https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg` and dearmor to `/usr/share/keyrings/vscodium-archive-keyring.gpg`
- **AND** write `/etc/apt/sources.list.d/vscodium.sources`
- **AND** execute `sudo apt update -qq`

### Requirement: Idempotent Mozilla APT Repository Configuration

The function `add_debian_mozilla_repo` SHALL configure the official Mozilla APT repository deb822 source, GPG keyring, and pinning priority 1000 if not already present.

#### Scenario: Mozilla repository already configured

- **GIVEN** `/etc/apt/sources.list.d/mozilla.sources` and `/etc/apt/keyrings/packages.mozilla.org.asc` exist
- **WHEN** `add_debian_mozilla_repo` is called
- **THEN** it SHALL output a skip message and return 0 without repeating configuration

#### Scenario: Adding Mozilla repository

- **GIVEN** Mozilla repository is not yet configured
- **WHEN** `add_debian_mozilla_repo` is called
- **THEN** it SHALL download the signing key to `/etc/apt/keyrings/packages.mozilla.org.asc`
- **AND** write `/etc/apt/sources.list.d/mozilla.sources`
- **AND** write APT pinning configuration to `/etc/apt/preferences.d/mozilla`
- **AND** execute `sudo apt update -qq`

### Requirement: Idempotent VirtualBox APT Repository Configuration

The function \`add_debian_virtualbox_repo\` SHALL configure the official Oracle VirtualBox APT repository deb822 source and GPG keyring if not already present.

#### Scenario: VirtualBox repository already configured

- **GIVEN** \`/etc/apt/sources.list.d/virtualbox.sources\` and \`/usr/share/keyrings/oracle-virtualbox-2016.gpg\` exist
- **WHEN** \`add_debian_virtualbox_repo\` is called
- **THEN** it SHALL output a skip message and return 0 without repeating downloads

#### Scenario: Adding VirtualBox repository

- **GIVEN** VirtualBox repository is not yet configured
- **WHEN** \`add_debian_virtualbox_repo\` is called
- **THEN** it SHALL download the GPG key from \`https://www.virtualbox.org/download/oracle_vbox_2016.asc\` and dearmor to \`/usr/share/keyrings/oracle-virtualbox-2016.gpg\`
- **AND** write \`/etc/apt/sources.list.d/virtualbox.sources\` for the detected codename
- **AND** execute \`sudo apt update -qq\`
