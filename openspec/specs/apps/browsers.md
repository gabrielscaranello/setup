# Specification: Web Browsers (`scripts/apps/setup-browsers.sh`)

## Purpose

Installs Chromium and official Mozilla Firefox browsers across all supported distributions, removing legacy ESR variants and configuring official Mozilla repositories on Debian and openSUSE Leap, installing vanilla Firefox and Chromium natively on Arch Linux, Fedora, and openSUSE Tumbleweed (where Firefox is default and only Chromium is installed), and using Flatpak for Chromium on Debian.

---

## Requirements

### Requirement: Chromium Distribution Packaging Strategy

The script SHALL determine the installation mechanism for Chromium based on the target distribution (`get_distro_id`):

- **Arch Linux (`arch`), Fedora (`fedora`), openSUSE (`opensuse-leap`, `opensuse-tumbleweed`, `opensuse`)**: SHALL install `chromium` directly from official repositories via `install_packages chromium`.
- **Debian (`debian`)**: SHALL install the official Flatpak package `org.chromium.Chromium` via Flathub (`install_flatpak_app "org.chromium.Chromium" "Chromium"`).
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

#### Scenario: Running on Fedora, Arch Linux, or openSUSE

- **GIVEN** a Fedora, Arch Linux, or openSUSE system
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** `chromium` SHALL be installed from native repositories

#### Scenario: Running on Debian

- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** `install_flatpak_app "org.chromium.Chromium" "Chromium"` SHALL be called

---

### Requirement: Firefox Distribution Packaging Strategy

The script SHALL install modern Firefox using distribution-native packaging on Arch Linux and Fedora, official Mozilla APT repository on Debian, and Mozilla OBS repository on openSUSE Leap, while skipping Firefox installation on openSUSE Tumbleweed where it is already the default browser:

- **Arch Linux (`arch`) & Fedora (`fedora`)**: SHALL install `firefox` and `firefox-i18n-pt-br` directly from repositories.
- **Debian (`debian`)**: SHALL purge `firefox-esr`, configure the official `packages.mozilla.org` APT repository with keyring and pinning priority 1000, and install `firefox` and `firefox-i18n-pt-br`.
- **openSUSE Tumbleweed (`opensuse-tumbleweed`)**: SHALL skip Firefox installation with an informational message because Firefox is default.
- **openSUSE Leap (`opensuse-leap`, `opensuse`)**: SHALL remove `firefox-esr` / `MozillaFirefox-esr` if present, configure the official openSUSE Mozilla repository (`add_opensuse_mozilla_repo`), and install `firefox` and `firefox-i18n-pt-br` (`MozillaFirefox` and `MozillaFirefox-translations-common`).

#### Scenario: Running on Fedora or Arch Linux

- **GIVEN** a Fedora or Arch Linux system (`get_distro_id` returns `fedora` or `arch`)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** `firefox` and `firefox-i18n-pt-br` SHALL be installed directly via `install_packages`

#### Scenario: Running on openSUSE Tumbleweed

- **GIVEN** an openSUSE Tumbleweed system (`get_distro_id` returns `opensuse-tumbleweed`)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** Firefox installation SHALL be skipped

#### Scenario: Running on openSUSE Leap

- **GIVEN** an openSUSE Leap system (`get_distro_id` returns `opensuse-leap` or `opensuse`)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** `firefox-esr` SHALL be removed if present
- **AND** `add_opensuse_mozilla_repo` SHALL configure the Mozilla repository
- **AND** `firefox` and `firefox-i18n-pt-br` SHALL be installed

#### Scenario: Running on Debian

- **GIVEN** a Debian system (`get_distro_id` returns `debian`)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** `firefox-esr` and `firefox-esr-l10n-pt-br` SHALL be removed if present
- **AND** Mozilla signing key SHALL be downloaded to `/etc/apt/keyrings/packages.mozilla.org.asc`
- **AND** `/etc/apt/sources.list.d/mozilla.sources` SHALL be created pointing to `https://packages.mozilla.org/apt`
- **AND** APT pinning priority 1000 SHALL be applied in `/etc/apt/preferences.d/mozilla`
- **AND** `firefox` and `firefox-i18n-pt-br` SHALL be installed from Mozilla APT
- **AND** subsequent runs SHALL skip Mozilla repository configuration idempotently

#### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-browsers.sh` runs
- **THEN** it SHALL exit with code 1 and display an error message
