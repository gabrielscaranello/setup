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

#### Scenario: Running full integration test suite across all supported distributions

- **GIVEN** `--integration` is specified without a specific `--distro` filter
- **WHEN** `tests/run-tests.sh` executes
- **THEN** it SHALL sequentially execute integration tests across `archlinux`, `debian`, and `fedora` containers

---

### Requirement: Unified Code Coverage Integration

When coverage generation is requested via `--coverage`, the test runner SHALL record coverage data using `kcov` across test suites and unify results.

#### Scenario: Coverage merging across test suites

- **GIVEN** `--coverage` is enabled during test execution
- **WHEN** tests complete across unit, archlinux, debian, and fedora test runs
- **THEN** coverage databases from all targets SHALL be merged into `coverage/`
- **AND** generate an HTML report accessible at `coverage/index.html`
