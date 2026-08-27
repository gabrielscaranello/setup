# Specification: Docker Engine & Plugins (`scripts/setup-docker.sh`)

## Purpose
Installs Docker container runtime, Docker Compose, Docker Buildx, and Containerd across supported distributions, configuring official Fedora CE repos where applicable, enabling the systemd service, and granting user group permissions.

---

## Requirements

### Requirement: Distribution Repository & Package Management
The script SHALL install Docker packages:
- **Fedora (`dnf`)**: SHALL add the official Docker CE repo via `dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo` if not present.
- **Package Installation**: SHALL invoke `install_packages docker docker-compose docker-buildx containerd`.

### Requirement: Systemd Daemon & User Group
The script SHALL:
- Enable and start `docker.service` via `systemctl`.
- Ensure group `docker` exists.
- Add target user (`$SUDO_USER` or `$USER`) to group `docker` via `usermod -aG docker`.

#### Scenario: Running on Fedora
- **GIVEN** a Fedora system
- **WHEN** `scripts/setup-docker.sh` is executed
- **THEN** Docker CE repo is added and packages installed from it

#### Scenario: Running on Debian or Arch Linux
- **GIVEN** a Debian or Arch Linux system
- **WHEN** `scripts/setup-docker.sh` is executed
- **THEN** Docker packages are installed without adding the Fedora repo file
