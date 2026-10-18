# Specification: DBeaver Database GUI (`scripts/apps/setup-dbeaver.sh`)

## Purpose

Installs DBeaver Community Edition (CE) database management tool using the optimal distribution packaging strategy per operating system.

---

## Requirements

### Requirement: Distribution Packaging Strategy

The script SHALL install DBeaver Community Edition via Flatpak (`io.dbeaver.DBeaverCommunity`) across all supported distributions:

- **All Supported Distros (`arch`, `debian`, `fedora`, `opensuse-leap`, `opensuse-tumbleweed`, `opensuse`)**: SHALL invoke `install_flatpak_app "io.dbeaver.DBeaverCommunity" "DBeaver"` to ensure up-to-date releases, isolate Java/JRE dependencies inside the Flatpak sandbox, and avoid system repository bloat.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on a supported distribution

- **GIVEN** a supported distribution (`arch`, `debian`, `fedora`, or `opensuse`)
- **WHEN** `scripts/apps/setup-dbeaver.sh` is executed
- **THEN** it SHALL invoke `install_flatpak_app io.dbeaver.DBeaverCommunity DBeaver`
- **AND** ensure Flatpak and Flathub are configured

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-dbeaver.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
