# Specification: Debian Repositories Configuration (`scripts/debian/_repositories.sh`)

## Purpose
Provides helper functions to detect Debian version codenames and idempotently configure official Debian Backports repositories.

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
