# Specification: Fedora Repositories Configuration (`scripts/system/fedora/_repositories.sh`)

## Purpose

Provides helper functions to idempotently configure third-party upstream repositories on Fedora (such as Docker CE and VSCodium).

---

## Requirements

### Requirement: Idempotent Docker CE DNF Repository Configuration

The function `add_fedora_docker_repo` SHALL configure the official Docker CE repository via DNF config-manager if `/etc/yum.repos.d/docker-ce.repo` does not exist.

#### Scenario: Docker CE repository already configured

- **GIVEN** `/etc/yum.repos.d/docker-ce.repo` exists
- **WHEN** `add_fedora_docker_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Adding Docker CE repository

- **GIVEN** `/etc/yum.repos.d/docker-ce.repo` does not exist
- **WHEN** `add_fedora_docker_repo` is called
- **THEN** it SHALL execute `sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo`

### Requirement: Idempotent VSCodium DNF Repository Configuration

The function `add_fedora_vscodium_repo` SHALL configure the official VSCodium repository at `/etc/yum.repos.d/vscodium.repo` if not present.

#### Scenario: VSCodium repository already configured

- **GIVEN** `/etc/yum.repos.d/vscodium.repo` exists
- **WHEN** `add_fedora_vscodium_repo` is called
- **THEN** it SHALL skip repository creation and return 0

#### Scenario: Adding VSCodium repository

- **GIVEN** `/etc/yum.repos.d/vscodium.repo` does not exist
- **WHEN** `add_fedora_vscodium_repo` is called
- **THEN** it SHALL write `/etc/yum.repos.d/vscodium.repo` with GPG verification enabled
