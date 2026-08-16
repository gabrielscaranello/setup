# Desktop Setup

Description
-----------

This repository contains cross-distro Linux desktop setup scripts. The goal is to provide a single set of scripts that work on Ubuntu/Debian, Fedora/RHEL, openSUSE and Arch Linux, installing and configuring tools such as Neovim and terminal adjustments.

Project purpose
---------------

- Automate provisioning of a desktop development environment across multiple Linux distributions.
- Keep scripts generic and idempotent, with a package-manager abstraction layer.
- Enable testing, reuse and maintenance via modular scripts under scripts/*.sh.

Quick usage
-----------

| action          | description                       |
| --------------- | --------------------------------- |
| `make help`     | Show Makefile help:               |
| `make all`      | Run full setup (runs `./main.sh`) |
| `make neovim`   | Run only Neovim setup             |
| `make nvm`      | Run only NVM/Node setup           |
| `make terminal` | Run only terminal setup           |
| `make clean`    | Clean temporary files:            |

Makefile — targets and description
---------------------------------

- help
  - Shows available targets and a brief description.

- all
  - Runs the main orchestrator `./main.sh`, which executes the setup scripts in sequence.

- neovim
  - Invokes `scripts/setup-neovim.sh` to install Neovim. The script ensures `nvm` is installed (it's required by the Neovim toolchain); Neovim is installed from the distro repository when the package manager is `dnf` or `zypper`, otherwise it builds from source.

- nvm
  - Invokes `scripts/setup-nvm.sh` to install nvm, Node and enable corepack; on Arch the `nvm` package from the repository is used.

- terminal
  - Invokes `scripts/setup-terminal.sh`. Currently a stub intended to install and configure terminal tools/themes/plugins.

- clean
  - Removes temporary artifacts (e.g., `/tmp/neovim`) to free space and ensure clean builds.

Directory layout
----------------

- main.sh - Orchestrator that runs scripts in sequence
- Makefile - Convenience runner (make all, make neovim, ...)
- scripts/_utils.sh - Package-manager abstraction and helper utilities
- scripts/setup-neovim.sh- Script to build/install Neovim
- scripts/setup-terminal.sh - Terminal setup script (to be implemented)

Requirements / prerequisites
---------------------------

- sudo access to install packages
- Git to clone repositories (Neovim)
- Bash shell (scripts use bash-specific features)

Contributing
------------

- Add new features as `scripts/setup-<name>.sh` and register them in `main.sh` and the Makefile if needed.
- Keep `_utils.sh` generic — do not add package-specific logic there.
- Validate scripts with `shellcheck -x scripts/*.sh` and test Makefile targets.
