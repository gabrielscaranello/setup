# Specification: Go Programming Language (`scripts/toolchain/setup-go.sh`)

## Purpose

Installs Go (via official binary archive or distribution repositories), exports `GOPATH` and binary directories in the user shell profile, and installs default Go developer tools (`dockerfmt`).

---

## Requirements

### Requirement: Distribution Installation Strategy

The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):

- **Fedora (`fedora`) & Arch Linux (`arch`)**: Install `golang` from native package repositories via `install_packages golang`.
- **Debian (`debian`)**: Download and extract official `go<version>.linux-amd64.tar.gz` to `/usr/local/go`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Shell Profile PATH Integration

The script SHALL idempotently append `export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"` to the user's profile (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).

### Requirement: Global Go Packages

The script SHALL install required global Go utilities (e.g. `github.com/reteps/dockerfmt@latest`) via `go install`, skipping if the binary is already in `PATH`.

#### Scenario: Running on Fedora or Arch Linux

- **GIVEN** a Fedora or Arch Linux system (`get_distro_id` returns `fedora` or `arch`)
- **WHEN** `scripts/toolchain/setup-go.sh` runs
- **THEN** `golang` is installed via native package manager
- **AND** global Go tools are installed

#### Scenario: Running on Debian

- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/toolchain/setup-go.sh` runs
- **THEN** official Go binary archive is installed in `/usr/local/go`
- **AND** shell profile contains Go PATH export
- **AND** `dockerfmt` binary is installed

#### Scenario: Re-running setup-go (Idempotency)

- **GIVEN** Go and `dockerfmt` are already installed
- **WHEN** `scripts/toolchain/setup-go.sh` is re-run
- **THEN** binary download and package installation are skipped

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/toolchain/setup-go.sh` runs
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
