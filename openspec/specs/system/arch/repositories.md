# Specification: Arch Linux Repositories Configuration (`scripts/system/arch/_repositories.sh`)

## Purpose

Provides repository helper utilities for Arch Linux, including idempotent enablement of the official `[multilib]` repository in `/etc/pacman.conf` and database synchronization.

---

## Requirements

### Requirement: Idempotent Multilib Repository Configuration

The function `add_arch_multilib_repo` SHALL ensure that the `[multilib]` section is active and uncommented in the Pacman configuration file (`/etc/pacman.conf` or `$PACMAN_CONF`).

#### Scenario: Pacman configuration file missing

- **GIVEN** the pacman configuration file does not exist
- **WHEN** `add_arch_multilib_repo` is called
- **THEN** it SHALL return 0 gracefully without errors

#### Scenario: Multilib already enabled

- **GIVEN** `/etc/pacman.conf` already contains an active `^[multilib]` section
- **WHEN** `add_arch_multilib_repo` is called
- **THEN** it SHALL skip configuration and return 0

#### Scenario: Multilib section commented out

- **GIVEN** `/etc/pacman.conf` contains a commented `#[multilib]` section
- **WHEN** `add_arch_multilib_repo` is called
- **THEN** it SHALL uncomment the `[multilib]` header and the immediate `Include` directive
- **AND** it SHALL synchronize the pacman package database via `sudo pacman -Sy --noconfirm`

#### Scenario: Multilib section completely missing

- **GIVEN** `/etc/pacman.conf` has no `[multilib]` section
- **WHEN** `add_arch_multilib_repo` is called
- **THEN** it SHALL append the `[multilib]` block with `Include = /etc/pacman.d/mirrorlist`
- **AND** it SHALL synchronize the pacman package database via `sudo pacman -Sy --noconfirm`
