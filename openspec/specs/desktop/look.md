# Setup Desktop Appearance Orchestrator (Look)

## Overview

Convenience orchestrator that sequentially applies cursor theme, GTK theme, and icon theme configurations across supported Desktop Environments (GNOME and KDE Plasma).

## Requirements

### Orchestration & Delegation

- **Sequential Execution**:
  1. Invokes `scripts/desktop/setup-cursor-theme.sh` to configure Bibata cursor theme.
  2. Invokes `scripts/desktop/setup-gtk-theme.sh` to configure adw-gtk3 dark theme.
  3. Invokes `scripts/desktop/setup-icon-theme.sh` to configure Papirus-Dark icon theme.
- **Idempotency**: Inherits idempotency from each underlying appearance script; safe to re-run multiple times.
- **Error Handling**: Fails fast with non-zero exit code if any of the underlying scripts fail.

## Test Scenarios

### Feature: Desktop Appearance Setup (Look)

**Scenario: Successful execution of all appearance components**

- **GIVEN** `setup-look.sh` is executed
- **WHEN** all underlying scripts succeed
- **THEN** it executes `setup-cursor-theme.sh`, `setup-gtk-theme.sh`, and `setup-icon-theme.sh` in order
- **AND** exits with return code 0

**Scenario: Failure propagation when an underlying script fails**

- **GIVEN** `setup-cursor-theme.sh` or another sub-script encounters a failure
- **WHEN** `setup-look.sh` is executed
- **THEN** it halts execution
- **AND** exits with a non-zero return code

**Scenario: Idempotent execution**

- **GIVEN** desktop appearance is already configured
- **WHEN** `setup-look.sh` is run again
- **THEN** it completes with exit code 0
