# Specification: openSUSE Repositories Configuration (`scripts/system/opensuse/_repositories.sh`)

## Purpose

Provides helper functions to idempotently configure repositories on openSUSE (such as Packman Essentials, Non-OSS, and VSCodium).

---

## Requirements

### Requirement: openSUSE Version Resolution

The function `get_opensuse_version` SHALL resolve the openSUSE version string from `/etc/os-release` (defaulting to `16.0` on Leap or `tumbleweed`).

#### Scenario: Resolving openSUSE Leap version

- **GIVEN** `/etc/os-release` contains `VERSION_ID="16.0"`
- **WHEN** `get_opensuse_version` is called
- **THEN** it SHALL return `16.0`

#### Scenario: Resolving openSUSE Tumbleweed

- **GIVEN** `/etc/os-release` contains `ID="opensuse-tumbleweed"`
- **WHEN** `get_opensuse_version` is called
- **THEN** it SHALL return `tumbleweed`

---

### Requirement: Idempotent Packman Essentials Repository Configuration

The function `add_opensuse_packman_repo` SHALL configure the Packman Essentials repository with priority 90 if not already configured.

#### Scenario: Packman repository already configured

- **GIVEN** `packman-essentials` repository exists in zypper
- **WHEN** `add_opensuse_packman_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Adding Packman repository

- **GIVEN** `packman-essentials` repository does not exist in zypper
- **WHEN** `add_opensuse_packman_repo` is called
- **THEN** it SHALL add the Packman Essentials repository with priority 90 and autorefresh enabled

---

### Requirement: Idempotent Non-OSS Repository Configuration

The function `add_opensuse_nonfree_repo` SHALL enable the Non-OSS repository if it is currently disabled.

#### Scenario: Non-OSS repository already enabled

- **GIVEN** `repo-non-oss` (or `openSUSE:repo-non-oss`) is enabled
- **WHEN** `add_opensuse_nonfree_repo` is called
- **THEN** it SHALL return 0 without error

#### Scenario: Enabling Non-OSS repository

- **GIVEN** `openSUSE:repo-non-oss` exists and is disabled
- **WHEN** `add_opensuse_nonfree_repo` is called
- **THEN** it SHALL enable the repository via `zypper mr -e`

---

### Requirement: Idempotent VSCodium Zypper Repository Configuration

The function `add_opensuse_vscodium_repo` SHALL configure the official VSCodium zypper repository at `/etc/zypp/repos.d/vscodium.repo` if not present.

#### Scenario: VSCodium repository already configured

- **GIVEN** `/etc/zypp/repos.d/vscodium.repo` exists or repo alias `vscodium` is present
- **WHEN** `add_opensuse_vscodium_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Adding VSCodium repository

- **GIVEN** VSCodium repository is not present
- **WHEN** `add_opensuse_vscodium_repo` is called
- **THEN** it SHALL import the VSCodium GPG key and add the repository via `zypper ar`
