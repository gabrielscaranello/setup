# Specification: CLI Productivity & Session Tools (`scripts/terminal/setup-cli.sh`)

## Purpose

Installs modern command-line productivity utilities (`bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `util-linux-user`), terminal connectivity/clipboard utilities (`openssh`, `dialog`, `keychain`, `clipboard`), and configures `zsh` as the user's default login shell across all supported Linux distributions and WSL environments without installing desktop-specific XDG folder generators.

---

## Requirements

### Requirement: Modern CLI & Productivity Tools Installation

The script SHALL validate the target distribution via `require_supported_distro` and install modern command-line utilities via `_install_cli_tools` using `install_packages`:

- `bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `util-linux-user`

### Requirement: Connectivity & Clipboard Utilities Installation

The script SHALL install SSH, terminal dialog, keychain, and clipboard utilities via `_install_cli_session_tools` using `install_packages`:

- `openssh`, `dialog`, `keychain`, `clipboard` (`wl-clipboard xclip` on Debian, `wl-clipboard xsel` on Fedora, `wl-clipboard` on Arch Linux and openSUSE)

### Requirement: Default Zsh Login Shell Configuration

When `zsh` is installed, `_configure_default_shell` SHALL ensure the current user's login shell is configured to the `zsh` binary path (using `sudo usermod -s` or `sudo chsh -s` when `/etc/passwd` does not already reflect `zsh`) and export `SHELL` to the `zsh` path for the active session.

#### Scenario: Running setup-cli on a supported distribution

- **GIVEN** a supported distribution (`debian`, `fedora`, `arch`, `opensuse-leap`, `opensuse-tumbleweed`, or `opensuse`)
- **WHEN** `scripts/terminal/setup-cli.sh` executes
- **THEN** CLI productivity tools (`bat`, `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `util-linux-user`) SHALL be installed
- **AND** connectivity and clipboard tools (`openssh`, `dialog`, `keychain`, `clipboard`) SHALL be installed
- **AND** default `zsh` shell SHALL be configured idempotently

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution (`require_supported_distro` returns 1)
- **WHEN** `scripts/terminal/setup-cli.sh` executes
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`

#### Scenario: Repeated execution (Idempotency)

- **GIVEN** CLI tools and `zsh` default shell are already configured
- **WHEN** `scripts/terminal/setup-cli.sh` is re-run
- **THEN** execution completes with exit code 0 without errors
