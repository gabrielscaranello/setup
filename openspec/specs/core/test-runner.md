# Specification: Multi-Distribution Test Runner & Container Infrastructure (`tests/run-tests.sh`)

## Purpose

Provides automated, isolated, and multi-distribution test orchestration for unit tests, Bats integration tests, and unified code coverage reports without executing commands or mutating state on the developer's host machine.

---

## Requirements

### Requirement: Multi-Distribution Container Support

The test harness SHALL provide containerized test environments for all supported distributions:

- Arch Linux (`tests/docker/archlinux.Dockerfile`)
- Debian 13 Trixie (`tests/docker/debian.Dockerfile`)
- Fedora 44 (`tests/docker/fedora.Dockerfile`)
- openSUSE Leap 16.1 (`tests/docker/opensuse.Dockerfile`)
- openSUSE Tumbleweed (`tests/docker/tumbleweed.Dockerfile`)

#### Scenario: Running full integration test suite across all supported distributions

- **GIVEN** `--integration` is specified without a specific `--distro` filter
- **WHEN** `tests/run-tests.sh` executes
- **THEN** it SHALL execute integration tests across `archlinux`, `debian`, `fedora`, `opensuse`, and `tumbleweed` containers (sequentially by default, or concurrently when `--parallel` is specified)
- **AND** it SHALL mount dedicated named volumes for package manager caches (`/var/cache/...`) to speed up subsequent runs
- **AND** it SHALL filter test files to only execute distro-relevant tests on each container

---

### Requirement: Concurrent Container Execution & Test Optimization

The test harness SHALL support accelerating test cycles:

- `--parallel` SHALL execute containerized distribution suites concurrently with buffered log output per distro.
- Each container image SHALL pre-install common test dependencies (`python3`, `pip`, `zsh`, `fzf`, `ripgrep`, `fd`, `tar`, `xz`, `unzip`, `procps`, `file`) and configure optimized parallel downloads.

---

### Requirement: Unified Code Coverage Integration

When coverage generation is requested via `--coverage`, the test runner SHALL record coverage data using `kcov` across test suites and unify results.

#### Scenario: Coverage merging across test suites

- **GIVEN** `--coverage` is enabled during test execution
- **WHEN** tests complete across unit, archlinux, debian, fedora, opensuse, and tumbleweed test runs
- **THEN** coverage databases from all targets SHALL be merged into `coverage/`
- **AND** generate an HTML report accessible at `coverage/index.html`
