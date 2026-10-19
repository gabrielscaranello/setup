# Specification: Node Version Manager & Node.js (`scripts/toolchain/setup-nvm.sh`)

## Purpose

Installs NVM (Node Version Manager), configures shell profile integration, installs Node.js v24, enables Corepack, and provisions global Corepack (`yarn@1`) and npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`).

---

## Requirements

### Requirement: Distribution Installation Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`)**: Install `nvm` from repository and load `/usr/share/nvm/init-nvm.sh`.
- **Debian (`debian`), Fedora (`fedora`) & openSUSE (`opensuse`, `opensuse-leap`, `opensuse-tumbleweed`)**: Download and run upstream `nvm` install script with `PROFILE=/dev/null`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Shell Profile Configuration & Directory Resolution

The script SHALL detect and support NVM installed at either `$HOME/.nvm` or `$XDG_CONFIG_HOME/nvm` (`$HOME/.config/nvm`), prioritizing any existing installation or standard XDG location. It SHALL add the standard NVM init block (`export NVM_DIR="..."`, source `nvm.sh` and `bash_completion`) to the user profile without duplication.

### Requirement: Node.js & Package Provisioning

The script SHALL:

- Install Node.js version 24 (`nvm install 24`) and alias default to 24.
- Enable Corepack (`corepack enable`).
- Install global Corepack packages (`corepack install -g yarn@1`).
- Install global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`) using `nvm exec 24 npm install -g`.

#### Scenario: Fresh execution on Fedora, Debian, or openSUSE

- **GIVEN** a clean Fedora, Debian, or openSUSE system (`get_distro_id` returns `fedora`, `debian`, or `opensuse*`)
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
