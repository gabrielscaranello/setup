# Specification: LMDE Repositories Configuration (`scripts/system/lmde/_repositories.sh`)

## Purpose

Provides helper functions to detect LMDE version codenames, verify or configure official Linux Mint repositories, and idempotently configure Debian Backports on LMDE.

---

## Requirements

### Requirement: LMDE and Debian Codename Detection

The helper SHALL resolve:

- The Linux Mint codename via `get_lmde_codename` from `/etc/os-release` (`VERSION_CODENAME`) or `/etc/linuxmint/info`, defaulting to `gigi`.
- The underlying Debian base codename via `get_lmde_debian_codename` from `/etc/os-release` (`DEBIAN_CODENAME`), defaulting to `trixie`.

#### Scenario: Detecting codenames on LMDE 7

- **GIVEN** `/etc/os-release` defines `VERSION_CODENAME=gigi` and `DEBIAN_CODENAME=trixie`
- **WHEN** `get_lmde_codename` and `get_lmde_debian_codename` are called
- **THEN** they return `gigi` and `trixie` respectively

---

### Requirement: Idempotent Official Mint Repository Configuration

The function `add_lmde_official_repo` SHALL ensure the official Linux Mint repository (`deb http://packages.linuxmint.com <codename> main upstream import backport`) and `linuxmint-keyring` are configured.

#### Scenario: Mint repository already present

- **GIVEN** `/etc/apt/sources.list.d/mint.list` or APT sources already contain `packages.linuxmint.com`
- **WHEN** `add_lmde_official_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Configuring Mint repository

- **GIVEN** Mint repository is not configured in APT sources
- **WHEN** `add_lmde_official_repo` is called
- **THEN** it SHALL ensure `linuxmint-keyring` is installed
- **AND** write `/etc/apt/sources.list.d/mint.list` with components `main upstream import backport`
- **AND** execute `sudo apt update -qq`

---

### Requirement: Idempotent Debian Backports Configuration on LMDE

The function `add_lmde_backports_repo` SHALL ensure that Debian backports for the underlying Debian codename are configured idempotently.

#### Scenario: Backports already present

- **GIVEN** APT sources already contain `<debian_codename>-backports`
- **WHEN** `add_lmde_backports_repo` is called
- **THEN** it SHALL skip creation and return 0

#### Scenario: Adding Backports on LMDE

- **GIVEN** no backports repository exists
- **WHEN** `add_lmde_backports_repo` is called
- **THEN** `/etc/apt/sources.list.d/backports.list` SHALL be written with `main contrib non-free non-free-firmware`
- **AND** execute `sudo apt update -qq`
