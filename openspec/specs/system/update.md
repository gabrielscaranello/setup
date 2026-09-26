# Specification: System Update & Package Upgrade (`scripts/system/setup-update.sh`)

## Purpose

Refreshes distribution package repositories and upgrades all installed system packages to their latest versions across supported distributions (**Debian 13**, **LMDE 7**, **Fedora 44**, and **Arch Linux**).

This module runs early in the setup sequence, immediately following the debloat cleanup step, ensuring all subsequent installations occur on an up-to-date system base.

---

## Requirements

### Requirement: Distribution-Agnostic System Update Dispatch

The script SHALL detect the current operating system using `require_supported_distro` or `get_distro_id`:

- On **Debian**: SHALL refresh APT metadata (`sudo apt update`) and perform a non-interactive package upgrade (`sudo apt upgrade -y`).
- On **LMDE**: SHALL perform updates via `mintupdate-cli upgrade -r -y` when `mintupdate-cli` is available, falling back to `sudo apt update` and `sudo apt upgrade -y` if missing or if execution fails.
- On **Fedora**: SHALL refresh DNF repository metadata and perform a non-interactive package upgrade (`sudo dnf upgrade -y --refresh`).
- On **Arch Linux**: SHALL refresh Pacman package databases and upgrade system packages (`sudo pacman -Syu --noconfirm`).
- On **Unsupported Distros**: SHALL print an error to stderr and exit with code 1.

#### Scenario: Updating system on Debian

- **GIVEN** Debian 13 (Trixie)
- **WHEN** `scripts/system/setup-update.sh` runs
- **THEN** APT cache SHALL be updated and packages upgraded via `apt upgrade -y`

#### Scenario: Updating system on LMDE

- **GIVEN** LMDE 7
- **WHEN** `scripts/system/setup-update.sh` runs
- **THEN** system SHALL be upgraded via `mintupdate-cli` when available, or via APT cache update and upgrade

#### Scenario: Updating system on Fedora

- **GIVEN** Fedora 44
- **WHEN** `scripts/system/setup-update.sh` runs
- **THEN** DNF cache SHALL be refreshed and packages upgraded via `dnf upgrade -y --refresh`

#### Scenario: Updating system on Arch Linux

- **GIVEN** Arch Linux
- **WHEN** `scripts/system/setup-update.sh` runs
- **THEN** Pacman databases SHALL be synced and system upgraded via `pacman -Syu --noconfirm`

---

### Requirement: Execution Override for Testing

The script SHALL honor `UPDATE_SKIP_SYSTEM_UPGRADE=1` to bypass full package downloading during automated unit and integration tests while exiting with code 0.

#### Scenario: Running with test override

- **GIVEN** `UPDATE_SKIP_SYSTEM_UPGRADE=1` is exported
- **WHEN** `scripts/system/setup-update.sh` runs
- **THEN** it SHALL output an informational message, skip invoking native package manager upgrades, and exit 0

---

## Scenarios

### Scenario: Full initial setup execution flow

- **GIVEN** any supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** `runners/main.sh` executes the initial setup pipeline
- **THEN** `setup-debloat.sh` SHALL execute first, followed immediately by `setup-update.sh`, before memory tuning and package provisioning
