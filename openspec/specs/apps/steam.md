# Specification: Steam & Gaming Tools (`scripts/apps/setup-steam.sh`)

## Purpose

Installs and configures Steam and modern gaming enhancement tools (compatibility/Proton manager, MangoHud performance overlay, Gamescope micro-compositor, and GameMode optimization daemon) across supported distributions (**Arch Linux**, **Fedora 44**, and **Debian 13 (Trixie)**).

---

## Requirements

### Requirement: Supported Distributions & Target Releases

The installation SHALL strictly target and support:

- **Arch Linux** (`arch`)
- **Fedora 44** (`fedora`)
- **Debian 13 (Trixie)** (`debian`)

### Requirement: Packaging Strategy by Distribution

1. **Debian 13 (`debian`)**:
   - To avoid polluting the Debian base system with 32-bit multiarch (`i386`) packages and library conflicts, Steam SHALL be installed via Flatpak (`com.valvesoftware.Steam`).
   - MangoHud and Gamescope for Steam SHALL be installed via their official Flathub Vulkan layer extensions:
     - `org.freedesktop.Platform.VulkanLayer.MangoHud`
     - `org.freedesktop.Platform.VulkanLayer.gamescope`

2. **Fedora 44 (`fedora`)**:
   - SHALL ensure the RPM Fusion Nonfree repository is configured via `add_fedora_rpmfusion_repo` from `scripts/system/fedora/_repositories.sh`.
   - SHALL install native packages via `install_packages`:
     - `steam` (from `rpmfusion-nonfree-steam`)
     - `mangohud` and `mangohud.i686` (64-bit and 32-bit Vulkan/OpenGL overlays)
     - `gamescope`
     - `gamemode`

3. **Arch Linux (`arch`)**:
   - SHALL verify and ensure the `[multilib]` repository is enabled in `/etc/pacman.conf` (uncommenting `[multilib]` and its mirrorlist include if commented) and update pacman database (`pacman -Sy`).
   - SHALL install native packages via `install_packages`:
     - `steam`
     - `mangohud` and `lib32-mangohud`
     - `gamescope`
     - `gamemode` and `lib32-gamemode`
     - `fonts-liberation` (`ttf-liberation` for font rendering in Steam UI)

### Requirement: Desktop Environment (DE) Differentiated Proton Manager

The compatibility tools manager (Proton manager) SHALL be installed via Flatpak across all distributions, tailored strictly to the active Desktop Environment detected via `get_desktop_environment`:

1. **GNOME**:
   - SHALL install **ProtonPlus** (`com.vysp3r.ProtonPlus`) via `install_flatpak_app`, providing native GTK4 / Libadwaita styling and integration.
2. **KDE Plasma**:
   - SHALL install **ProtonUp-Qt** (`net.davidotek.pupgui2`) via `install_flatpak_app`, providing native Qt-based integration.
3. **Unknown / Unrecognized**:
   - Per project DE policy, SHALL skip Proton manager installation and log that it was skipped due to unrecognized desktop environment.

### Requirement: MangoJuice Flatpak Installation

MangoJuice (`io.github.radiolamp.mangojuice`) SHALL be installed via Flatpak (`install_flatpak_app`) across all distributions to provide a modern graphical interface for configuring MangoHud.

### Requirement: Cross-Distro Package Mapping (`scripts/packages.conf`)

Package divergences across distributions SHALL be mapped in `scripts/packages.conf`:

- `gamemode`:
  - `debian`: `gamemode`
  - `fedora`: `gamemode`
  - `arch`: `gamemode lib32-gamemode`
- `mangohud`:
  - `debian`: `-`
  - `fedora`: `mangohud mangohud.i686`
  - `arch`: `mangohud lib32-mangohud`
- `steam`:
  - `debian`: `-`
  - `fedora`: `steam`
  - `arch`: `steam`

_(Note: `gamescope` shares the exact same package name on all supported managers and is resolved via fallback)_.

---

## Scenarios

### Scenario: Running on Debian 13 under GNOME

- **GIVEN** a Debian 13 system running GNOME (`distro="debian"`, `de="gnome"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL install `com.valvesoftware.Steam` via `install_flatpak_app`
- **AND** it SHALL install `org.freedesktop.Platform.VulkanLayer.MangoHud` and `org.freedesktop.Platform.VulkanLayer.gamescope` via `install_flatpak_app`
- **AND** it SHALL install `com.vysp3r.ProtonPlus` via `install_flatpak_app`

### Scenario: Running on Debian 13 under KDE Plasma

- **GIVEN** a Debian 13 system running KDE Plasma (`distro="debian"`, `de="plasma"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL install `com.valvesoftware.Steam` via `install_flatpak_app`
- **AND** it SHALL install `net.davidotek.pupgui2` via `install_flatpak_app`

### Scenario: Running on Fedora 44 under GNOME

- **GIVEN** a Fedora 44 system running GNOME (`distro="fedora"`, `de="gnome"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL call `add_fedora_rpmfusion_repo`
- **AND** it SHALL install native packages `steam`, `mangohud`, `gamescope`, `gamemode`
- **AND** it SHALL install `com.vysp3r.ProtonPlus` via `install_flatpak_app`

### Scenario: Running on Fedora 44 under KDE Plasma

- **GIVEN** a Fedora 44 system running KDE Plasma (`distro="fedora"`, `de="plasma"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL call `add_fedora_rpmfusion_repo`
- **AND** it SHALL install native packages `steam`, `mangohud`, `gamescope`, `gamemode`
- **AND** it SHALL install `net.davidotek.pupgui2` via `install_flatpak_app`

### Scenario: Running on Arch Linux under GNOME

- **GIVEN** an Arch Linux system running GNOME (`distro="arch"`, `de="gnome"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL ensure `[multilib]` is enabled in `/etc/pacman.conf`
- **AND** it SHALL install native packages `steam`, `mangohud`, `gamescope`, `gamemode`, `fonts-liberation`
- **AND** it SHALL install `com.vysp3r.ProtonPlus` via `install_flatpak_app`

### Scenario: Running on Arch Linux under KDE Plasma

- **GIVEN** an Arch Linux system running KDE Plasma (`distro="arch"`, `de="plasma"`)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL ensure `[multilib]` is enabled in `/etc/pacman.conf`
- **AND** it SHALL install native packages `steam`, `mangohud`, `gamescope`, `gamemode`, `fonts-liberation`
- **AND** it SHALL install `net.davidotek.pupgui2` via `install_flatpak_app`

### Scenario: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/apps/setup-steam.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error to `stderr`
