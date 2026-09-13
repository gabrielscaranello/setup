# Specification: System Packages Debloat & Cleanup (`scripts/system/setup-debloat.sh`)

## Purpose

Removes unused default packages, redundant applications, legacy utilities, and distro bloatware on **Debian 13** and **Fedora 44**, tailored specifically to the active Desktop Environment (**GNOME** or **KDE Plasma**).

On **Arch Linux**, this module gracefully bypasses package removal because Arch installations are user-composed and inherently minimal.

---

## Requirements

### Requirement: Distribution Support and Arch Linux Graceful Bypass

The script SHALL detect the current distribution using `get_distro_id`:

- On **Debian**: SHALL execute Debian-tailored debloat operations using `apt purge -y` and `apt autoremove --purge -y`.
- On **Fedora**: SHALL execute Fedora-tailored debloat operations using `dnf remove -y` and `dnf autoremove -y`.
- On **Arch Linux**: SHALL print an informational message indicating debloat is unnecessary on minimal Arch systems and exit cleanly with code 0.
- On **Unknown / Unsupported Distros**: SHALL print an error to stderr and exit with code 1.

#### Scenario: Running on Arch Linux

- **GIVEN** current distribution is `arch`
- **WHEN** `scripts/system/setup-debloat.sh` executes
- **THEN** it SHALL exit 0 without invoking any package manager commands

---

### Requirement: Common Unused Packages Removal

The script SHALL remove cross-desktop unused packages on supported distros (Debian and Fedora):

- **Office**: `libreoffice-core` (Debian & Fedora), `libreoffice-common` (Debian).
- **Terminal Fallback**: `xterm` (replaced by Kitty).
- **Text Editor**: `kate` (replaced by Ghostwriter / Neovim / VSCodium).
- **CD/DVD Burning**: `brasero`.
- **Desktop Backup**: `deja-dup` (replaced by Timeshift).
- **BitTorrent**: `transmission-common`.

#### Scenario: Removing common packages on Debian or Fedora

- **GIVEN** standard desktop installation on Debian or Fedora
- **WHEN** common debloat executes
- **THEN** LibreOffice, xterm, kate, brasero, deja-dup, and transmission-common SHALL be purged/removed

---

### Requirement: Distribution-Specific Removals

The script SHALL handle packages unique to specific distributions:

- **Debian**: SHALL purge `gimp` from APT to prevent conflicts with the newer Flatpak build installed via `setup-gimp.sh`.
- **Fedora**: SHALL remove `mediawriter` and `gnome-shell-extension-background-logo` (Fedora desktop watermark).

---

### Requirement: GNOME Desktop Environment Debloat

When the detected Desktop Environment is `gnome`, the script SHALL remove redundant GNOME pre-installed software:

- **Audio & Video**: `totem`, `gnome-music`, `rhythmbox`, `decibels` (Fedora).
- **Camera & Photos**: `cheese`, `gnome-snapshot` (Debian) / `snapshot` (Fedora), `gnome-photos`, `shotwell`.
- **Terminals**: `gnome-terminal`, `ptyxis` (replaced by Kitty).
- **Tools, Communication & PIM**:
  - `evolution`
  - `gnome-boxes`
  - `gnome-characters`
  - `gnome-connections`
  - `gnome-maps`
  - `gnome-sound-recorder`
  - `gnome-tour`
  - `simple-scan`
  - `gedit`
  - `remmina`
  - `polari`
- **Preservation Guard**: `gnome-weather` SHALL be preserved and NOT removed.

#### Scenario: Running debloat under GNOME

- **GIVEN** active desktop environment is `gnome`
- **WHEN** `scripts/system/setup-debloat.sh` executes
- **THEN** legacy media players, cameras, terminals, and demo utilities SHALL be removed
- **AND** `gnome-weather` SHALL remain untouched

---

### Requirement: KDE Plasma Desktop Environment Debloat

When the detected Desktop Environment is `plasma`, the script SHALL remove redundant KDE pre-installed software:

- **Audio & Video**: `dragonplayer` (Debian) / `dragon` (Fedora), `juk`.
- **Terminal**: `konsole` (replaced by Kitty).
- **Web Browser**: `konqueror` (replaced by Firefox / Chromium).
- **KDE PIM & Messaging**: `akregator`, `kdepim`, `kdepim-runtime`, `kmail`, `kontact`, `korganizer`, `konversation`.
- **Acessibility & Redundant Utilities**:
  - `kamera`
  - `kcalc`
  - `kfind`
  - `kmag`, `kmousetool`, `kmouth`
  - `kontrast`
  - `kuiviewer`
  - `kwalletmanager`
  - `sweeper`
  - `skanlite`

#### Scenario: Running debloat under KDE Plasma

- **GIVEN** active desktop environment is `plasma`
- **WHEN** `scripts/system/setup-debloat.sh` executes
- **THEN** Dragon player, Juk, Konsole, Konqueror, KDE PIM, and legacy KDE accessibility tools SHALL be removed

---

### Requirement: Idempotency and Test Execution Override

The script SHALL:

- Filter candidate removal packages to only those currently installed, or safely ignore non-installed packages without triggering script failure (`set -e`).
- Clean up orphaned dependencies via autoremove (`apt autoremove --purge -y` on Debian, `dnf autoremove -y` on Fedora).
- Honor `DEBLOAT_SKIP_PACKAGE_REMOVAL=1` to allow dry-run and non-destructive unit testing.

#### Scenario: Idempotency on second run

- **GIVEN** all debloat packages have already been removed from the system
- **WHEN** `scripts/system/setup-debloat.sh` executes again
- **THEN** it SHALL exit 0 without error or attempting invalid removals

---

## Scenarios

### Scenario: Full Debloat on Debian GNOME

- **GIVEN** Debian 13 with GNOME
- **WHEN** `scripts/system/setup-debloat.sh` runs
- **THEN** common bloat, debian `gimp`, and GNOME bloatware SHALL be purged via `apt purge`

### Scenario: Full Debloat on Fedora KDE Plasma

- **GIVEN** Fedora 44 with KDE Plasma
- **WHEN** `scripts/system/setup-debloat.sh` runs
- **THEN** common bloat and KDE Plasma bloatware (including `dragon`, `akregator`, `kmail`, `kontact`, `korganizer`) SHALL be removed via `dnf remove`
