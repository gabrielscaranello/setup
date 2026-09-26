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
- LMDE 7 Gigi (`tests/docker/lmde.Dockerfile`)

#### Scenario: Running integration tests targeting LMDE

- **GIVEN** the `--distro=lmde` parameter or `DISTRO=lmde` variable is passed to `tests/run-tests.sh`
- **WHEN** integration tests are executed
- **THEN** it SHALL build/verify the `setup-test-lmde` container image
- **AND** execute the integration tests inside the isolated container
- **AND** verify that `/etc/os-release` and distro detection tools identify the environment as `lmde`

#### Scenario: Running full integration test suite across all supported distributions

- **GIVEN** `--integration` is specified without a specific `--distro` filter
- **WHEN** `tests/run-tests.sh` executes
- **THEN** it SHALL sequentially execute integration tests across `archlinux`, `debian`, `fedora`, and `lmde` containers

---

### Requirement: Unified Code Coverage Integration

When coverage generation is requested via `--coverage`, the test runner SHALL record coverage data using `kcov` across test suites and unify results.

#### Scenario: Coverage merging across test suites

- **GIVEN** `--coverage` is enabled during test execution
- **WHEN** tests complete across unit, archlinux, debian, fedora, and lmde test runs
- **THEN** coverage databases from all targets SHALL be merged into `coverage/`
- **AND** generate an HTML report accessible at `coverage/index.html`
