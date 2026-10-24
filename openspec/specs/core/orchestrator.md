# Central Orchestrator & CLI Dispatcher (`main.sh` & `runners/main.sh`)

## Overview

The central CLI orchestrator provides a single, unified entry point (`./main.sh` and `make <target>`) for running setup modules individually or orchestrating the complete desktop setup pipeline with automatic distribution detection across **Debian**, **Fedora**, **Arch Linux**, **openSUSE** (Leap and Tumbleweed), and **WSL**.

## Requirements

### 1. Unified Dispatching (`main.sh` & `runners/main.sh`)

- `main.sh` acts as root launcher forwarding all parameters to `runners/main.sh`.
- When invoked without arguments, it defaults to displaying interactive CLI help (`show_help`).
- `show_help` documents all supported modules, available distro commands (`arch`, `debian`, `fedora`, `opensuse`, `wsl`), and the global setup target (`all`).

- Modules are declared in a single registry (`runners/_modules.sh`, format `name|aliases|path|description`). Both `run_module` dispatch and `show_help` are generated from it, so adding a module requires only a new registry entry.
- Extra CLI arguments after the module name are forwarded to the module script, and execution always starts from the repository root.

### 2. Automatic Distribution Delegation (`run_all`)

- When `is_wsl` returns 0 on `debian`, delegates full setup pipeline to `runners/wsl.sh`; on any other distribution inside WSL, outputs an informative error message and exits with status 1.
- Otherwise, queries `get_distro_id` to detect the running Linux distribution and delegates full setup pipeline to the dedicated runner:
  - `debian`: executes `runners/debian.sh`
  - `fedora`: executes `runners/fedora.sh`
  - `arch`: executes `runners/arch.sh`
  - `opensuse*`: executes `runners/opensuse.sh`
- When the distribution is unrecognized or unsupported, outputs an informative error message and exits with status 1.

### 3. Direct Module and Runner Invocations (`run_module`)

- Supports direct invocation of individual toolchain, desktop, and app scripts (`cli`, `python`, `gh`, etc.).
- Supports direct invocation of distro and environment runners (`arch`, `debian`, `fedora`, `opensuse`, `wsl`) to allow explicit target overrides.
- For unknown commands or targets, outputs an error message and shows help with exit status 1.

## Test Scenarios

### Feature: Central CLI Dispatcher

**Scenario: Display help by default or when requested**

- **GIVEN** `runners/main.sh` is invoked with no arguments, `help`, or `--help`
- **WHEN** execution starts
- **THEN** it displays available setup commands including `all`, `arch`, `debian`, `fedora`, `opensuse`, and `wsl`
- **AND** exits with status 0

**Scenario: Auto-delegation to Debian, Fedora, and Arch runners**

- **GIVEN** `get_distro_id` returns `debian`, `fedora`, or `arch`
- **WHEN** `run_all` is executed
- **THEN** it delegates to `runners/debian.sh`, `runners/fedora.sh`, or `runners/arch.sh` respectively
- **AND** exits with status 0

**Scenario: Direct distro runner execution**

- **GIVEN** a specific runner target is passed (e.g. `arch`, `debian`, `fedora`)
- **WHEN** `run_module` is called
- **THEN** it executes the corresponding runner script
- **AND** exits with status 0

**Scenario: Unsupported distribution error handling**

- **GIVEN** `get_distro_id` returns an unsupported distribution (e.g. `ubuntu`)
- **WHEN** `run_all` is executed
- **THEN** it outputs an error stating unsupported distribution and supported options
- **AND** exits with status 1
