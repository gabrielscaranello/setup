# Specification: Neovim Editor & Runtime Dependencies (`scripts/toolchain/setup-neovim.sh`)

## Purpose

Installs or builds the latest Neovim editor, ensuring pre-requisite toolchains (NVM, Node.js, and on Debian: Rust/Cargo for tree-sitter requirements), build dependencies, clipboard providers, and ecosystem runtime dependencies (`ripgrep`, `fd-find`, `imagemagick`, `sqlite`, `tidy`, `protobuf`, etc.) are satisfied across all supported distributions.

---

## Requirements

### Requirement: Mandatory Toolchain Prerequisites

The script SHALL ensure that `scripts/toolchain/setup-nvm.sh` and `scripts/toolchain/setup-go.sh` are executed across all distributions before any Neovim installation or configuration steps proceed.

#### Scenario: Running setup across any supported distribution

- **GIVEN** any supported Linux distribution (Arch Linux, Fedora, or Debian)
- **WHEN** `scripts/toolchain/setup-neovim.sh` is executed
- **THEN** it SHALL invoke `setup-nvm.sh` and `setup-go.sh` first to guarantee Node.js, npm, and Go toolchains are present

---

### Requirement: Neovim Runtime Dependencies & Clipboard Providers

The script SHALL install runtime dependencies, language runtimes, package managers, clipboard tools, and build tools via `install_packages` across distributions:

- **Common across all distributions**:
  - `jq`, `ripgrep`, `fd-find`, `clipboard`, `imagemagick`, `sqlite`, `tidy`, `protobuf-compiler`, `unzip`
- **Distro-specific independent dependencies**:
  - **Debian (`debian`)**: `luarocks`, `python3`, `python-venv` (`python3-venv`)
  - **Fedora (`fedora`)**: `luarocks`, `cargo`, `lua-5.1`
  - **Arch Linux (`arch`)**: `build-tools` (`base-devel`), `rust`, `tree-sitter-cli`, `luarocks`

#### Scenario: Installing runtime packages on Debian

- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/toolchain/setup-neovim.sh` installs runtime dependencies
- **THEN** common packages (`jq`, `fd-find`, `xclip`, `imagemagick`, `sqlite3`, `libsqlite3-dev`, `tidy`, `protobuf-compiler`, `ripgrep`, `unzip`) and Debian-specific packages (`luarocks`, `python3`, `python3-venv`) SHALL be installed

#### Scenario: Installing runtime packages on Fedora

- **GIVEN** a Fedora system (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/toolchain/setup-neovim.sh` installs runtime dependencies
- **THEN** common packages (`jq`, `fd-find`, `xsel`, `ImageMagick`, `sqlite`, `sqlite-devel`, `libtidy`, `protobuf-compiler`, `ripgrep`, `unzip`) and Fedora-specific packages (`luarocks`, `cargo`, `lua-5.1`) SHALL be installed

#### Scenario: Installing runtime packages on Arch Linux

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/toolchain/setup-neovim.sh` installs runtime dependencies
- **THEN** common packages (`jq`, `fd`, `wl-clipboard`, `imagemagick`, `sqlite`, `tidy`, `protobuf`, `ripgrep`, `unzip`) and Arch-specific packages (`base-devel`, `rust`, `tree-sitter-cli`, `luarocks`) SHALL be installed

---

### Requirement: Distribution Installation Strategy

The script SHALL determine the Neovim binary installation mechanism based on the target distribution (`get_distro_id`):

- **Fedora (`fedora`) & Arch Linux (`arch`)**: SHALL install `neovim` directly from official repositories using `install_packages neovim`.
- **Debian (`debian`)**: SHALL ensure `scripts/toolchain/setup-rust.sh` is executed (for `tree-sitter-cli`), install required build dependencies (`build-tools`, `ninja-build`, `gcc-cxx`, `cmake`, `gettext-tools`, `curl`, `git`, `file`), clone Neovim `stable` branch into `/tmp/neovim`, build using `make -j$(nproc) CMAKE_BUILD_TYPE=RelWithDebInfo`, generate a Debian package using `cpack -G DEB`, and install the resulting `.deb` package via `dpkg -i`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

#### Scenario: Running on Fedora or Arch Linux

- **GIVEN** a Fedora or Arch Linux system (`get_distro_id` returns `fedora` or `arch`)
- **WHEN** `scripts/toolchain/setup-neovim.sh` is executed
- **THEN** `_ensure_nvm` is executed
- **AND** `_ensure_go` is executed
- **AND** runtime dependencies are installed via `install_packages`
- **AND** `install_packages neovim` is called directly

#### Scenario: Running on Debian

- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/toolchain/setup-neovim.sh` is executed
- **THEN** `_ensure_nvm` is executed
- **AND** `_ensure_go` is executed
- **AND** `_ensure_rust` is executed
- **AND** build dependencies and runtime packages are installed via `install_packages`
- **AND** Neovim source is cloned, built, packaged with `cpack -G DEB`, and installed via `sudo dpkg -i`

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/toolchain/setup-neovim.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
