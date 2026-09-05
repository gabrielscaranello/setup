# Specification: Telegram Desktop (`scripts/apps/setup-telegram.sh`)

## Purpose
Installs Telegram Desktop messaging application across supported distributions, enabling RPM Fusion Free repository on Fedora, using native distribution packages on Arch Linux and Fedora, and downloading/integrating the latest upstream release binary on Debian with version checking and XDG desktop entry integration.

---

## Requirements

### Requirement: Distribution Installation Strategy
The script SHALL determine the installation mechanism based on the target distribution (`get_distro_id`):
- **Arch Linux (`arch`)**: SHALL install `telegram-desktop` directly from official repositories using `install_packages telegram-desktop`.
- **Fedora (`fedora`)**: SHALL verify if `rpmfusion-free` repository is present in `dnf repolist`; if missing, it SHALL query the Fedora version (`rpm -E %fedora`, with fallback to `41` if undefined) and install `rpmfusion-free-release-<version>.noarch.rpm` before installing `telegram-desktop` via `install_packages`.
- **Debian (`debian`)**: SHALL ensure utility packages (`curl`, `wget`, `tar`, `xz-utils`) are present, query GitHub API (`https://api.github.com/repos/telegramdesktop/tdesktop/releases/latest`) to discover latest version, download `tsetup.<version>.tar.xz`, extract the archive to `~/.local/opt/telegram-desktop`, create a symlink in `~/.local/bin/telegram-desktop`, and configure the XDG desktop entry `~/.local/share/applications/telegramdesktop.desktop`.
- **Unsupported Distros / Derivatives**: SHALL exit with code 1 and output an error message to `stderr`.

---

### Requirement: Version Verification & Idempotency
On Debian, the script SHALL check if Telegram is already installed (`~/.local/opt/telegram-desktop/Telegram`, `command -v telegram-desktop`, or `~/.local/bin/telegram-desktop`) and parse its local version (`grep -Po 'Telegram Desktop \K[^ ]*'`).
- If the local version matches the latest GitHub release tag, downloading and extracting the tarball SHALL be skipped.
- Desktop integration (symlinks and desktop entry) SHALL still be ensured.

---

### Requirement: Desktop Integration & MIME Handlers (Debian Upstream)
On Debian standalone binary installation, the script SHALL:
- Create `~/.local/bin` and `~/.local/share/applications` directories if missing.
- Create symlink `~/.local/bin/telegram-desktop` -> `~/.local/opt/telegram-desktop/Telegram`.
- Write `~/.local/share/applications/telegramdesktop.desktop` configured with `Exec=~/.local/opt/telegram-desktop/Telegram -- %u`, `Icon=telegram`, categories (`Network;InstantMessaging;Chat;`), and MIME association `MimeType=x-scheme-handler/tg;`.

#### Scenario: Running on Arch Linux
- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`)
- **WHEN** `scripts/apps/setup-telegram.sh` is executed
- **THEN** it SHALL call `install_packages telegram-desktop`

#### Scenario: Running on Fedora
- **GIVEN** a Fedora system (`get_distro_id` returns `fedora`)
- **WHEN** `scripts/apps/setup-telegram.sh` is executed
- **THEN** RPM Fusion Free repository SHALL be installed if not already configured
- **AND** `install_packages telegram-desktop` SHALL be executed

#### Scenario: Running on Debian (Fresh Installation)
- **GIVEN** a Debian system without Telegram installed (`get_distro_id` returns `debian`)
- **WHEN** `scripts/apps/setup-telegram.sh` is executed
- **THEN** latest tarball is downloaded from GitHub and extracted to `~/.local/opt/telegram-desktop`
- **AND** `~/.local/bin/telegram-desktop` symlink is created
- **AND** `telegramdesktop.desktop` is deployed with `x-scheme-handler/tg;` support

#### Scenario: Running on Debian when already up to date
- **GIVEN** a Debian system with the latest Telegram version already installed in `~/.local/opt/telegram-desktop` (`get_distro_id` returns `debian`)
- **WHEN** `scripts/apps/setup-telegram.sh` is executed
- **THEN** tarball download and extraction SHALL be skipped
- **AND** desktop integration and symlinks SHALL be verified

#### Scenario: Running on an unsupported distribution
- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-telegram.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`
