# Specification: Gitflow CJS (`scripts/toolchain/setup-gitflow.sh`)

## Purpose

Installs Gitflow CJS (`v2.2.1`) CLI extensions using the official upstream installer.

---

## Requirements

### Requirement: Version Check & Installation

The script SHALL:

- Check if `git flow version` matches `v2.2.1` and skip installation if already present.
- Download `gitflow-installer.sh`, execute `sudo bash gitflow-installer.sh install version v2.2.1`, and clean up `/tmp/gitflow-installer`.

#### Scenario: Installing Gitflow

- **GIVEN** `git-flow` is not installed
- **WHEN** `scripts/toolchain/setup-gitflow.sh` runs
- **THEN** Gitflow CJS v2.2.1 is installed into `/usr/local/bin`
