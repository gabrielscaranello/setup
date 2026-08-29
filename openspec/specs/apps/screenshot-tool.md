# Specification: Screenshot Tool (`scripts/apps/setup-screenshot-tool.sh`)

## Purpose

Installs and configures the appropriate desktop screenshot utility based on the active desktop environment:

- **GNOME**: Installs **Flameshot** (`flameshot`) via `install_packages flameshot`.
- **KDE Plasma**: Installs **Spectacle** (`spectacle` / `kde-spectacle`) via `install_packages spectacle`.
- **Unknown Desktop Environment**: Does nothing, adhering strictly to the repository's DE handling policy.

---

## Requirements

### Requirement: Desktop Environment Adaptive Strategy

The script SHALL detect the active desktop environment via `get_desktop_environment`:

- **GNOME (`gnome`)**: SHALL install `flameshot` using `install_packages flameshot`.
- **KDE Plasma (`plasma`)**: SHALL install `spectacle` using `install_packages spectacle`.
- **Unknown / Headless / Unsupported DE (`unknown`)**: SHALL output a skip notice, do nothing, and exit cleanly with code 0.

#### Scenario: Running on GNOME

- **GIVEN** a desktop running GNOME (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/apps/setup-screenshot-tool.sh` is executed
- **THEN** it SHALL call `install_packages flameshot`

#### Scenario: Running on KDE Plasma

- **GIVEN** a desktop running KDE Plasma (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/apps/setup-screenshot-tool.sh` is executed
- **THEN** it SHALL call `install_packages spectacle`

#### Scenario: Running on an unknown or unrecognized desktop environment

- **GIVEN** an unknown desktop environment (`get_desktop_environment` returns `unknown`)
- **WHEN** `scripts/apps/setup-screenshot-tool.sh` is executed
- **THEN** it SHALL output a notice and exit with status 0 without installing any packages

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unrecognized operating system
- **WHEN** `scripts/apps/setup-screenshot-tool.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
