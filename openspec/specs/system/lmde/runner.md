# LMDE Setup Runner

## Overview

Provide a dedicated distribution runner script (`runners/lmde.sh`) for **LMDE 7** (Linux Mint Debian Edition) that orchestrates the complete modular setup pipeline, configuring base packages, hardware drivers, toolchains, GUI applications, Cinnamon Spices, desktop preferences, and ergonomics.

## Requirements

### 1. Desktop Environment Selection & Persistence

- Prompts or resolves the target Desktop Environment using `ensure_desktop_environment`, defaulting to `cinnamon` for LMDE installations.
- Persists selected environment to `$HOME/.config/setup/desktop-environment` for subsequent script steps.

### 2. Sequential Pipeline Execution

- Executes `run_pipeline` with descriptive labels and failure-halting semantics (`set -euo pipefail`).
- **Initial Setup Phase (`COMMON_INITIAL_STEPS`)**:
  - `system/setup-debloat.sh`: Purges Mint bloatware and unnecessary packages.
  - `system/setup-update.sh`: Refreshes package lists and applies updates.
  - `system/setup-swap.sh`: Tunes vm memory and swap/zram.
  - `system/setup-packages.sh`: Installs core packages and LMDE desktop utilities (`nemo-fileroller`, `xclip`, `zram-tools`, `libu2f-udev`, `numlockx`).
- **Snapshot Phase**:
  - `system/setup-timeshift.sh`: Configures Timeshift with LMDE exclusion and inclusion rules.
- **Application & Desktop Customization Phase (`COMMON_POST_STEPS`)**:
  - Sets up graphics, codecs (`mint-meta-codecs`), Docker, Flatpak, and Firewall.
  - Deploys GUI apps (Firefox, Chromium, VSCodium, Obsidian, DBeaver, OnlyOffice, GIMP, Telegram, Discord, Steam).
  - Deploys CLI and toolchain environments (fonts, Gitflow, Go, NVM/Node, Kitty, Lazygit, Lazydocker, Neovim from source).
  - Configures appearance (`Bibata-Modern-Ice`, `Papirus-Dark`, `Colloid-Dark-Catppuccin`).
  - Installs and configures Cinnamon Spices (`color-picker@fmete`, `transparent-panels-reloaded`).
  - Configures Cinnamon panel layout, applet positions, window manager preferences (`:close`, center placement), Night Light, and hotcorners.
  - Cleans up desktop menu entries (`setup-hide-apps.sh`).

## Test Scenarios

### Feature: LMDE Setup Runner

**Scenario: Execute LMDE pipeline orchestrator**

- **GIVEN** `runners/lmde.sh` is sourced or executed
- **WHEN** `run_all` is called
- **THEN** it ensures desktop environment defaulting to `cinnamon`
- **AND** it invokes `run_pipeline` with the LMDE setup pipeline name and steps
- **AND** returns exit code 0
