# Specification: Go Programming Language (`scripts/setup-go.sh`)

## Purpose
Installs Go (via official binary archive or distribution repositories), exports `GOPATH` and binary directories in the user shell profile, and installs default Go developer tools (`dockerfmt`).

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL:
- **Fedora (`dnf`) & Arch Linux (`pacman`)**: Install `golang` from native package repositories.
- **Debian (`apt`)**: Download and extract official `go<version>.linux-amd64.tar.gz` to `/usr/local/go`.

### Requirement: Shell Profile PATH Integration
The script SHALL idempotently append `export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"` to the user's profile (`~/.zshrc`, `~/.bashrc`, or `~/.profile`).

### Requirement: Global Go Packages
The script SHALL install required global Go utilities (e.g. `github.com/reteps/dockerfmt@latest`) via `go install`, skipping if the binary is already in `PATH`.

#### Scenario: Running on Debian
- **GIVEN** a Debian system
- **WHEN** `scripts/setup-go.sh` runs
- **THEN** official Go binary archive is installed in `/usr/local/go`
- **AND** shell profile contains Go PATH export
- **AND** `dockerfmt` binary is installed

#### Scenario: Re-running setup-go (Idempotency)
- **GIVEN** Go and `dockerfmt` are already installed
- **WHEN** `scripts/setup-go.sh` is re-run
- **THEN** binary download and package installation are skipped
