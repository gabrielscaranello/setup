# Specification: Rust Toolchain & Utilities (`scripts/toolchain/setup-rust.sh`)

## Purpose

Installs Rust compiler, Cargo package manager via official `rustup`, sets stable toolchain, configures shell profile PATH, and installs developer CLI tools (`tree-sitter-cli`).

---

## Requirements

### Requirement: Toolchain Installation Strategy

The script SHALL determine the toolchain installation strategy based on distribution:

- **openSUSE Tumbleweed (`opensuse-tumbleweed`)**: SHALL install `rust` and `cargo` directly from distribution repositories via `install_packages rust cargo`.
- **Debian (`debian`), Fedora (`fedora`), Arch Linux (`arch`) & openSUSE Leap (`opensuse-leap`, `opensuse`)**: Download and run official `https://sh.rustup.rs` non-interactively (`-y --default-toolchain stable --no-modify-path`) if `rustup` is missing, and add `[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"` to the user shell profile.

### Requirement: Cargo Packages Installation

The script SHALL inspect installed Cargo packages (`cargo install --list`) and install `tree-sitter-cli` via `cargo install tree-sitter-cli` if not present.

#### Scenario: Running on openSUSE Tumbleweed

- **GIVEN** an openSUSE Tumbleweed system (`get_distro_id` returns `opensuse-tumbleweed`)
- **WHEN** `scripts/toolchain/setup-rust.sh` runs
- **THEN** `rust` and `cargo` packages are installed from distribution repositories
- **AND** `tree-sitter-cli` is installed via Cargo

#### Scenario: Installing Rust when already present

- **GIVEN** `rustup` or `cargo` is already in `PATH`
- **WHEN** `scripts/toolchain/setup-rust.sh` runs
- **THEN** toolchain installation is skipped idempotently
