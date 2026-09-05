# Specification: Multi-Distribution Package Mapping (`scripts/packages.conf`)

## Purpose
Establishes a declarative translation table that maps generic software package identifiers across Debian (`apt`), Fedora (`dnf`), and Arch Linux (`pacman`).

---

## Requirements

### Requirement: Declarative Multi-Distro Resolution
The mapping file SHALL maintain pipe-separated (`|`) records with columns: `Generic Name | Debian Package | Fedora Package | Arch Linux Package`, resolved primarily by target distribution identifier (`debian`, `fedora`, `arch`) with backwards-compatible support for package manager aliases (`apt`, `dnf`, `pacman`).

#### Scenario: Translating package with distro naming differences
- **GIVEN** a package has distinct naming across distributions (e.g. `golang` resolving to `go` on Arch, `akmod-nvidia` on Fedora, `nvidia-driver` on Debian)
- **WHEN** referenced by its generic name in an installation script via `install_packages`
- **THEN** it SHALL resolve to the exact distro-native package name specified in `packages.conf` for the active distribution

#### Scenario: Package unsupported or unnecessary on a specific distro
- **GIVEN** a package is not applicable or not in repositories for a distro (indicated by `-`)
- **WHEN** resolved for that target distro
- **THEN** the mapping SHALL return `-` indicating installation should be bypassed

#### Scenario: Package format and structure compliance
- **GIVEN** the `packages.conf` file
- **THEN** entries SHALL be ordered alphabetically by generic package name
- **AND** maintain column alignment with at least one blank space before and after every `|` separator
- **AND** avoid containing packages whose names are identical across all supported distros
