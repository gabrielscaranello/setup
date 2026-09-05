# Specification: Node Version Manager & Node.js (`scripts/toolchain/setup-nvm.sh`)

## Purpose
Installs NVM (Node Version Manager), configures shell profile integration, installs Node.js v24, enables Corepack, and provisions global Corepack (`yarn@1`) and npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`).

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):
- **Arch Linux (`arch`)**: Install `nvm` from repository and load `/usr/share/nvm/init-nvm.sh`.
- **Debian (`debian`) & Fedora (`fedora`)**: Download and run upstream `nvm` install script with `NVM_PROFILE=/dev/null`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Shell Profile Configuration
The script SHALL add the standard NVM init block (`export NVM_DIR="$HOME/.nvm"`, source `nvm.sh` and `bash_completion`) to the user profile without duplication.

### Requirement: Node.js & Package Provisioning
The script SHALL:
- Install Node.js version 24 (`nvm install 24`) and alias default to 24.
- Enable Corepack (`corepack enable`).
- Install global Corepack packages (`corepack install -g yarn@1`).
- Install global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`) using `nvm exec 24 npm install -g`.

#### Scenario: Fresh execution on Fedora or Debian
- **GIVEN** a clean Fedora or Debian system (`get_distro_id` returns `fedora` or `debian`)
- **WHEN** `scripts/toolchain/setup-nvm.sh` runs
- **THEN** NVM is installed to `~/.nvm`, Node 24 is set as default, and yarn/copilot packages are installed

#### Scenario: Fresh execution on Arch Linux
- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/toolchain/setup-nvm.sh` runs
- **THEN** NVM package is installed from repository

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/toolchain/setup-nvm.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
