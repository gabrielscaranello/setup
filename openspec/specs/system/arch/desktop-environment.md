# Specification: Arch Linux Desktop Environment Installation (`scripts/system/arch/setup-desktop-environment.sh`)

## Purpose

Provisions complete graphical desktop environments on **Arch Linux** systems starting from minimal or headless console installations. Supports both **KDE Plasma** (default) and **GNOME**, providing interactive selection with CLI/environment variable overrides, installing the respective display/login managers (`plasma-login-manager` vs `gdm`), shell components, Wayland/PipeWire audio stack, XDG desktop portals, and enabling systemd login services.

---

## Requirements

### Requirement: Distribution Guard

The script SHALL only execute on Arch Linux systems (`is_distro arch`). On non-Arch systems (such as Debian or Fedora), the script SHALL exit gracefully with status code 0 without modifying the system.

#### Scenario: Running on non-Arch distribution

- **GIVEN** a Debian or Fedora system (`is_distro arch` returns false)
- **WHEN** `scripts/system/arch/setup-desktop-environment.sh` executes
- **THEN** execution terminates immediately with exit code 0 and an informative message

#### Scenario: Running on Arch Linux

- **GIVEN** an Arch Linux system (`is_distro arch` returns true)
- **WHEN** `scripts/system/arch/setup-desktop-environment.sh` executes
- **THEN** desktop environment resolution and provisioning proceeds

---

### Requirement: Target Desktop Environment Resolution

The script SHALL determine the target desktop environment (`plasma` or `gnome`) according to the following precedence order:

1. **Existing Desktop Environment**: If `get_desktop_environment` returns `plasma` or `gnome`, that environment SHALL be selected.
2. **CLI Argument**: If invoked with `--de=plasma` or `--de=gnome`, the specified environment SHALL be selected.
3. **Environment Variable**: If the `TARGET_DE` variable is set to `plasma` or `gnome`, that environment SHALL be selected.
4. **Interactive Prompt**: If running in an interactive terminal (`[ -t 0 ]`) and no environment is detected or specified, the script SHALL prompt the user to choose:
   - `1) KDE Plasma (Recomendado)`
   - `2) GNOME`
5. **Non-Interactive Default**: If running non-interactively without an environment or parameter specified, the script SHALL default to `plasma`.

#### Scenario: Detecting already running desktop

- **GIVEN** an Arch system with an active GNOME session (`get_desktop_environment` returns `gnome`)
- **WHEN** resolution executes
- **THEN** target DE SHALL resolve to `gnome` without user prompting

#### Scenario: Overriding via CLI argument

- **GIVEN** a minimal Arch system with no active DE
- **WHEN** script is invoked with `--de=gnome`
- **THEN** target DE SHALL resolve to `gnome`

#### Scenario: Overriding via environment variable

- **GIVEN** `TARGET_DE=plasma` in the environment
- **WHEN** script executes without CLI arguments
- **THEN** target DE SHALL resolve to `plasma`

#### Scenario: Non-interactive fallback

- **GIVEN** a minimal Arch system without TTY input (`[ -t 0 ]` false) and no flags or variables set
- **WHEN** resolution executes
- **THEN** target DE SHALL default to `plasma`

---

### Requirement: KDE Plasma Stack Provisioning

When the resolved target DE is `plasma`, the script SHALL:

1. **Packages**: Install the KDE Plasma desktop stack via `install_packages`:
   - `plasma-login-manager`
   - `plasma-desktop`, `plasma-workspace`, `plasma-workspace-wallpapers`, `plasma-nm`, `plasma-pa`, `powerdevil`, `kscreen`, `polkit-kde-agent`, `plasma-integration`
   - `pipewire`, `pipewire-pulse`, `wireplumber`, `gst-plugin-pipewire`
   - `xdg-desktop-portal-kde`, `egl-wayland`, `xorg-xwayland`
2. **Login Service**: Enable the `plasmalogin.service` via `systemctl enable plasmalogin`.

#### Scenario: Provisioning KDE Plasma

- **GIVEN** target DE resolved to `plasma`
- **WHEN** KDE Plasma provisioning executes
- **THEN** KDE packages SHALL be installed via `install_packages`
- **AND** `plasmalogin.service` SHALL be enabled in systemd

---

### Requirement: GNOME Stack Provisioning

When the resolved target DE is `gnome`, the script SHALL:

1. **Packages**: Install the GNOME desktop stack via `install_packages`:
   - `gdm`
   - `gnome-shell`, `mutter`, `gnome-control-center`, `gnome-session`, `gsettings-desktop-schemas`
   - `pipewire`, `pipewire-pulse`, `wireplumber`
   - `xdg-desktop-portal-gnome`, `xorg-xwayland`
2. **Login Service**: Enable the `gdm.service` via `systemctl enable gdm`.

#### Scenario: Provisioning GNOME

- **GIVEN** target DE resolved to `gnome`
- **WHEN** GNOME provisioning executes
- **THEN** GNOME packages SHALL be installed via `install_packages`
- **AND** `gdm.service` SHALL be enabled in systemd

---

### Requirement: Idempotency and Script Structure Contract

The script SHALL adhere to the project coding standard:

- Executable with `set -euo pipefail`.
- Sources `scripts/_utils.sh` safely.
- Separates private functions by concern:
  - `_resolve_target_de`
  - `_install_plasma_stack`
  - `_install_gnome_stack`
- Exposes an execution guard (`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`) to permit sourcing in Bats unit tests without automatic execution.

#### Scenario: Re-executing provisioning

- **GIVEN** desktop environment already provisioned
- **WHEN** `scripts/system/arch/setup-desktop-environment.sh` is executed a second time
- **THEN** execution completes with exit code 0 without duplicate operations or errors
