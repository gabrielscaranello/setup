# 📋 Future Implementations & Roadmap (TODO)

This document tracks the ordered roadmap, technical requirements, and detailed task checklists for progressively expanding distribution support across this setup repository.

---

## 🧭 Discovery & Reference Repositories

Before starting the implementation for each distribution, consult the author's reference repositories for upstream package choices, configurations, and scripts:

- **Linux Mint & LMDE**: [gabrielscaranello/mint-setup](https://github.com/gabrielscaranello/mint-setup) (main branch and all branches, including LMDE variants).
- **Zorin OS 18.1**: [gabrielscaranello/zorin-setup](https://github.com/gabrielscaranello/zorin-setup) (layout profiles, Zorin Appearance dconf keys, and themes).

---

## 🍃 Phase 1: Linux Mint (Ubuntu LTS Base + Cinnamon)

> **Objective**: Add native support for Linux Mint, introducing **Cinnamon 6+** as the 3rd supported Desktop Environment in this repository, respecting Mint's native no-snap policy and native package repositories.

- [x] **Discovery & Specification**:
  - [x] Inspect packages, themes, and configurations in `gabrielscaranello/mint-setup` (main branch).
  - [x] Author OpenSpec specification in `openspec/specs/system/linuxmint.md` with GIVEN/WHEN/THEN scenarios.
- [x] **System Detection & Package Mapping**:
  - [x] Update `scripts/utils/_system.sh` (`get_distro_id` detecting `ID=linuxmint` with `ID_LIKE=ubuntu`).
  - [x] Update `require_supported_distro` and `is_distro "linuxmint"`.
  - [x] Configure package resolution for Linux Mint in `scripts/utils/_packages.sh` and `scripts/packages.conf`.
- [x] **Desktop Environment (Cinnamon)**:
  - [x] Update `scripts/utils/_desktop.sh` to detect `cinnamon` via `get_desktop_environment`.
  - [x] Create `scripts/desktop/setup-cinnamon.sh` (dark mode via gsettings, keybindings, default terminal emulator).
  - [x] Configure recommended settings for the Nemo file manager.
- [x] **Repositories & System Policy**:
  - [x] Validate default repositories and keyring for `packages.linuxmint.com`.
  - [x] Ensure Mint's native snap-blocking policy (`/etc/apt/preferences.d/nosnap.pref`) is respected.
- [x] **Orchestration & Runners**:
  - [x] Create `runners/linuxmint.sh`.
  - [x] Register `linuxmint|Linux Mint|linuxmint.sh` in the `DISTRO_RUNNERS` array in `runners/main.sh`.
  - [x] Expose runner targets in `Makefile` and register commands in `runners/_modules.sh` if applicable.
- [x] **Testing & Quality Assurance**:
  - [x] Create test Dockerfile `tests/docker/linuxmint.Dockerfile`.
  - [x] Update `tests/run-tests.sh` to support `--distro=linuxmint`.
  - [x] Create Bats unit tests covering all conditional branches for Linux Mint.
  - [x] Execute and verify all unit tests and integration tests inside Docker.

---

## 📦 Phase 2: LMDE (Linux Mint Debian Edition)

> **Objective**: Bridge the existing Debian base with the Mint/Cinnamon ecosystem developed in Phase 1.

- [ ] **Discovery & Specification**:
  - [ ] Inspect LMDE branches in `gabrielscaranello/mint-setup`.
  - [ ] Author OpenSpec specification in `openspec/specs/system/lmde.md`.
- [ ] **System Detection & Architectural Reuse**:
  - [ ] Update `scripts/utils/_system.sh` (`get_distro_id` detecting `ID=linuxmint` with `ID_LIKE=debian` or LMDE identifier).
  - [ ] Direct package resolution to the `DEBIAN` column (`apt|2`) in `scripts/utils/_packages.sh`.
  - [ ] Reuse `scripts/desktop/setup-cinnamon.sh` created in Phase 1.
- [ ] **System Repositories**:
  - [ ] Configure official Debian repositories (`deb.debian.org`) combined with the Mint Debian suite (`packages.linuxmint.com`).
- [ ] **Orchestration & Runners**:
  - [ ] Create `runners/lmde.sh`.
  - [ ] Register `lmde|LMDE|lmde.sh` in `DISTRO_RUNNERS` (`runners/main.sh`).
- [ ] **Testing & Quality Assurance**:
  - [ ] Create `tests/docker/lmde.Dockerfile`.
  - [ ] Update `tests/run-tests.sh` to support `--distro=lmde`.
  - [ ] Create Bats unit tests and validate integration inside Docker.

---

## 🚀 Phase 3: Ubuntu 26.04 LTS (Modern Ubuntu)

> **Objective**: Support modern Ubuntu 26.04 LTS (GNOME 50+, Plasma 6.x), with complete snap removal, vanilla GNOME-like desktop experience, native Yaru GTK theming, and Papirus icon theme with Yaru-colored folders.

- [ ] **Specification & Planning**:
  - [ ] Author OpenSpec specification in `openspec/specs/system/ubuntu.md`.
- [ ] **System Detection & deb822 Format**:
  - [ ] Update `scripts/utils/_system.sh` (`get_distro_id` detecting `ID=ubuntu`, `VERSION_ID="26.04"`).
  - [ ] Standardize third-party repositories in declarative `.sources` format (deb822) under `/etc/apt/sources.list.d/`.
- [ ] **Debloat & Snap Policy**:
  - [ ] Implement complete purge routine for `snapd` and its dependencies.
  - [ ] Deploy `/etc/apt/preferences.d/nosnap.pref` preventing snap packages from returning via APT.
  - [ ] Purge telemetry packages (`apport`, `whoopsie`, `ubuntu-report`, `popularity-contest`).
  - [ ] Prioritize Flathub and the official Mozilla APT repository for native `.deb` Firefox.
- [ ] **Visual Identity & Theming**:
  - [ ] Configure vanilla GNOME aesthetic (disable/hide `ubuntu-dock` and `ding` desktop icons).
  - [ ] Preserve native Ubuntu GTK theme (`Yaru` / `Yaru-dark`).
  - [ ] Apply Papirus icon theme with Yaru folder colors (`papirus-folders -C yaru` in `scripts/desktop/setup-icon-theme.sh`).
- [ ] **Orchestration & Runners**:
  - [ ] Create `runners/ubuntu.sh`.
  - [ ] Register `ubuntu|Ubuntu|ubuntu.sh` in `DISTRO_RUNNERS` (`runners/main.sh`).
- [ ] **Testing & Quality Assurance**:
  - [ ] Create `tests/docker/ubuntu-2604.Dockerfile`.
  - [ ] Update `tests/run-tests.sh` for `--distro=ubuntu`.
  - [ ] Validate full coverage with Bats (unit and Docker integration tests).

---

## 🎨 Phase 4: Zorin OS 18.1 (Custom GNOME Desktop)

> **Objective**: Integrate Zorin OS 18.1 leveraging the Ubuntu 26.04 foundation, preserving identity and compatibility with Zorin Appearance.

- [ ] **Discovery & Specification**:
  - [ ] Inspect configurations and dconf keys in `gabrielscaranello/zorin-setup`.
  - [ ] Author OpenSpec specification in `openspec/specs/system/zorin.md`.
- [ ] **System Detection**:
  - [ ] Update `scripts/utils/_system.sh` (`get_distro_id` detecting `ID=zorin`).
  - [ ] Reuse Ubuntu 26.04 package mappings and repository infrastructure built in Phase 3.
- [ ] **Desktop Environment (Zorin Appearance)**:
  - [ ] Adapt `scripts/desktop/setup-gnome.sh` for Zorin compatibility mode.
  - [ ] Preserve Zorin layout and menu extensions (`zorin-menu`, taskbar layouts).
  - [ ] Apply fonts, dark mode, and terminal emulator configurations while respecting Zorin Appearance.
- [ ] **Orchestration & Runners**:
  - [ ] Create `runners/zorin.sh`.
  - [ ] Register `zorin|Zorin OS|zorin.sh` in `DISTRO_RUNNERS` (`runners/main.sh`).
- [ ] **Testing & Quality Assurance**:
  - [ ] Create `tests/docker/zorin.Dockerfile`.
  - [ ] Update `tests/run-tests.sh` for `--distro=zorin`.
  - [ ] Validate unit and Docker integration tests.

---

## 🔒 Quality Gates (Mandatory per Phase)

No phase is considered complete without passing all of the following gates:

1. **OpenSpec Specification**: `openspec/specs/system/<distro>.md` authored and updated.
2. **Linting & Formatting**: `make lint` and `make format` passing cleanly.
3. **Unit Tests**: `make test-unit` passing with 100% coverage on new distro conditional branches.
4. **Integration Tests in Docker**: `./tests/run-tests.sh --integration --distro=<distro>` passing without failures.
