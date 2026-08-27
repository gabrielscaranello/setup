# Specification: Node Version Manager & Node.js (`scripts/setup-nvm.sh`)

## Purpose
Installs NVM (Node Version Manager), configures shell profile integration, installs Node.js v24, enables Corepack, and provisions global Corepack (`yarn@1`) and npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`).

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL:
- **Arch Linux (`pacman`)**: Install `nvm` from repository and load `/usr/share/nvm/init-nvm.sh`.
- **Debian (`apt`) & Fedora (`dnf`)**: Download and run upstream `nvm` install script with `NVM_PROFILE=/dev/null`.

### Requirement: Shell Profile Configuration
The script SHALL add the standard NVM init block (`export NVM_DIR="$HOME/.nvm"`, source `nvm.sh` and `bash_completion`) to the user profile without duplication.

### Requirement: Node.js & Package Provisioning
The script SHALL:
- Install Node.js version 24 (`nvm install 24`) and alias default to 24.
- Enable Corepack (`corepack enable`).
- Install global Corepack packages (`corepack install -g yarn@1`).
- Install global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`) using `nvm exec 24 npm install -g`.

#### Scenario: Fresh execution on Fedora
- **GIVEN** clean Fedora system
- **WHEN** `scripts/setup-nvm.sh` runs
- **THEN** NVM is installed to `~/.nvm`, Node 24 is set as default, and yarn/copilot packages are installed
