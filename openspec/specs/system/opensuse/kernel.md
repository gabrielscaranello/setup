# Specification: openSUSE Leap Kernel Backports (`scripts/system/opensuse/setup-kernel.sh`)

## Purpose

Installs the latest modern stable Linux kernel and development headers from the official `Kernel:stable:Backport` repository on openSUSE Leap installations, bypassing execution on openSUSE Tumbleweed and non-openSUSE systems.

---

## Requirements

### Requirement: Distribution Guard

The script SHALL check the target distribution using `get_distro_id`. If run on openSUSE Tumbleweed (which already runs the latest rolling kernel) or non-openSUSE systems, it SHALL output an informative skip message and exit cleanly with code 0.

### Requirement: Kernel Repository Configuration

The script SHALL ensure the `Kernel:stable` repository is configured via `add_opensuse_kernel_backports_repo` (`https://download.opensuse.org/repositories/Kernel:/stable/standard`).

### Requirement: Kernel & Headers Installation

The script SHALL install `kernel-default` and `kernel-default-devel` packages from `Kernel:stable`.

#### Scenario: Execution on openSUSE Leap

- **GIVEN** an openSUSE Leap installation (`get_distro_id` returns `opensuse` or `opensuse-leap`)
- **WHEN** `scripts/system/opensuse/setup-kernel.sh` is executed
- **THEN** `add_opensuse_kernel_backports_repo` SHALL configure the `Kernel:stable` repository
- **AND** `kernel-default` and `kernel-default-devel` SHALL be installed from `Kernel:stable`

#### Scenario: Execution on openSUSE Tumbleweed

- **GIVEN** an openSUSE Tumbleweed system (`get_distro_id` returns `opensuse-tumbleweed`)
- **WHEN** `scripts/system/opensuse/setup-kernel.sh` is executed
- **THEN** it SHALL output a skip notice and exit with status 0

#### Scenario: Execution on non-openSUSE systems

- **GIVEN** a Debian, Fedora, or Arch Linux system
- **WHEN** `scripts/system/opensuse/setup-kernel.sh` is executed
- **THEN** it SHALL output a skip notice and exit with status 0
