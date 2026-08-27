# Specification: Neovim Editor (`scripts/setup-neovim.sh`)

## Purpose
Installs or builds the latest Neovim editor, ensuring pre-requisite toolchains (NVM, Node.js, and on Debian: Rust/Cargo for tree-sitter requirements) and build dependencies are satisfied before installing native packages or building from source.

---

## Requirements

### Requirement: Mandatory Toolchain Prerequisites
The script SHALL ensure that `setup-nvm.sh` is executed across all distributions before any Neovim installation steps proceed.

#### Scenario: Running setup across any supported distribution
- **GIVEN** any supported Linux distribution (Arch Linux, Fedora, or Debian)
- **WHEN** `scripts/setup-neovim.sh` is executed
- **THEN** it SHALL invoke `setup-nvm.sh` first to guarantee Node.js and npm toolchains are present

---

### Requirement: Distribution Installation Strategy
The script SHALL determine the installation mechanism based on the active package manager:
- **Fedora (`dnf`) & Arch Linux (`pacman`)**: SHALL install `neovim` directly from official repositories using `install_packages neovim`.
- **Debian (`apt`)**: SHALL ensure `setup-rust.sh` is executed (for `tree-sitter-cli`), install required build dependencies (`build-tools`, `ninja-build`, `gcc-cxx`, `cmake`, `gettext-tools`, `curl`, `git`, `file`), clone Neovim `stable` branch into `/tmp/neovim`, build using `make -j$(nproc) CMAKE_BUILD_TYPE=RelWithDebInfo`, generate a Debian package using `cpack -G DEB`, and install the resulting `.deb` package via `dpkg -i`.

#### Scenario: Running on Fedora or Arch Linux
- **GIVEN** a Fedora or Arch Linux system
- **WHEN** `scripts/setup-neovim.sh` is executed
- **THEN** `_ensure_nvm` is executed
- **AND** `install_packages neovim` is called directly

#### Scenario: Running on Debian
- **GIVEN** a Debian system
- **WHEN** `scripts/setup-neovim.sh` is executed
- **THEN** `_ensure_nvm` is executed
- **AND** `_ensure_rust` is executed
- **AND** build dependencies are installed via `install_packages`
- **AND** Neovim source is cloned, built, packaged with `cpack -G DEB`, and installed via `sudo dpkg -i`

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution
- **WHEN** `scripts/setup-neovim.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
