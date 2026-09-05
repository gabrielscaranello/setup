# Specification: Docker Engine & Plugins (`scripts/toolchain/setup-docker.sh`)

## Purpose
Installs Docker container runtime, Docker Compose, Docker Buildx, and Containerd across supported distributions, configuring official Fedora CE repos where applicable, enabling the systemd service, and granting user group permissions.

---

## Requirements

### Requirement: Distribution Repository & Package Management
The script SHALL install Docker packages based on the target distribution (`get_distro_id`):
- **Fedora (`fedora`)**: SHALL add the official Docker CE repo via `add_fedora_docker_repo` from `scripts/system/fedora/_repositories.sh` if not present.
- **Debian (`debian`) & Arch Linux (`arch`)**: SHALL NOT add the Fedora Docker repo file.
- **Package Installation**: SHALL invoke `install_packages docker docker-compose docker-buildx containerd`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and write an error message to `stderr`.

### Requirement: Systemd Daemon & User Group
The script SHALL:
- Enable and start `docker.service` via `systemctl`.
- Ensure group `docker` exists.
- Add target user (`$SUDO_USER` or `$USER`) to group `docker` via `usermod -aG docker`.

#### Scenario: Running on Fedora
- **GIVEN** a Fedora system (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/toolchain/setup-docker.sh` is executed
- **THEN** Docker CE repo is added and packages installed from it

#### Scenario: Running on Debian or Arch Linux
- **GIVEN** a Debian or Arch Linux system (`get_distro_id` returns `debian` or `arch`)
- **WHEN** `scripts/toolchain/setup-docker.sh` is executed
- **THEN** Docker packages are installed without adding the Fedora repo file

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/toolchain/setup-docker.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
