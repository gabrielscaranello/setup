# Specification: Rust Toolchain & Utilities (`scripts/setup-rust.sh`)

## Purpose
Installs Rust compiler, Cargo package manager via official `rustup`, sets stable toolchain, configures shell profile PATH, and installs developer CLI tools (`tree-sitter-cli`).

---

## Requirements

### Requirement: Rustup Installation & Profile Configuration
The script SHALL:
- Download and run `https://sh.rustup.rs` non-interactively (`-y --default-toolchain stable --no-modify-path`) if `rustup` is missing.
- Add `[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"` to the user shell profile.

### Requirement: Cargo Packages Installation
The script SHALL inspect installed Cargo packages (`cargo install --list`) and install `tree-sitter-cli` via `cargo install tree-sitter-cli` if not present.

#### Scenario: Installing Rust when already present
- **GIVEN** `rustup` is already in `PATH`
- **WHEN** `scripts/setup-rust.sh` runs
- **THEN** rustup download and profile additions are skipped idempotently
