# Capability Spec: Firewall Setup (`scripts/security/setup-firewall.sh`)

## 📌 Feature Overview

Installs and enables the appropriate firewall service and optional Desktop Environment GUI frontend across supported Linux distributions (Debian 13, Fedora 44, and Arch Linux).

---

## 🎯 Distro & Desktop Environment Matrix

| Distribution                          | Backend Service | Default Rules                 | GNOME GUI         | KDE Plasma GUI     |
| :------------------------------------ | :-------------- | :---------------------------- | :---------------- | :----------------- |
| **Debian 13 (Trixie)**                | `ufw`           | deny incoming, allow outgoing | `gufw`            | `plasma-firewall`  |
| **Fedora 44**                         | `firewalld`     | default active                | `firewall-config` | `plasma-firewall`  |
| **Arch Linux**                        | `ufw`           | deny incoming, allow outgoing | `gufw`            | `plasma-firewall`  |
| **openSUSE (Leap 16.1 & Tumbleweed)** | `firewalld`     | default active                | `firewall-config` | `plasma6-firewall` |

_Note: Headless or unknown desktop environments configure only the CLI backend service without installing GUI frontends._

---

## 📐 Requirements & Behavioral Rules

1. **Distribution Dispatch & Backend Installation**:
   - Detect target distribution via `get_distro_id`.
   - On **Debian (`debian`)** and **Arch Linux (`arch`)**: Install `ufw` via `install_packages ufw`.
   - On **Fedora (`fedora`)** and **openSUSE (`opensuse*`)**: Install `firewalld` via `install_packages firewalld`.
   - On **Unsupported Distros / Derivatives**: Exit with code 1 and write error to `stderr`.
2. **Service Enablement & Fail-Safe Configuration**:
   - On **Arch Linux**:
     - Enable and start `ufw.service` explicitly via systemd (`sudo systemctl enable --now ufw.service` or `sudo systemctl enable ufw.service`).
     - Enable `ufw` rules engine (`sudo ufw --force enable`).
     - Set default policies: incoming `deny`, outgoing `allow` (`sudo ufw default deny incoming`, `sudo ufw default allow outgoing`).
   - On **Debian 13**:
     - Enable `ufw` (`sudo ufw --force enable`).
     - Set default policies: incoming `deny`, outgoing `allow` (`sudo ufw default deny incoming`, `sudo ufw default allow outgoing`).
     - Enable systemd service (`sudo systemctl enable ufw.service` or `sudo systemctl enable --now ufw.service` if systemd is active).
   - On **Fedora 44** and **openSUSE (Leap & Tumbleweed)**:
     - Enable systemd service (`sudo systemctl enable --now firewalld.service` or `sudo systemctl enable firewalld.service` if systemd is active).
3. **Desktop Environment Frontend Integration**:
   - Detect DE using `get_desktop_environment` from `scripts/_utils.sh`.
   - When DE is `gnome`:
     - On **Debian** or **Arch Linux**: Install `gufw` (`install_packages gufw`).
     - On **Fedora** or **openSUSE**: Install `firewall-config` (`install_packages firewall-config`).
   - When DE is `plasma`:
     - On **Debian**, **Fedora**, **Arch Linux**, or **openSUSE**: Install `plasma-firewall` (`install_packages plasma-firewall`, which maps to `plasma6-firewall` on openSUSE).
   - When DE is `unknown` or unrecognized: Do not install GUI packages.
4. **Idempotency**:
   - Running the script repeatedly must preserve rules, avoid errors, and not corrupt firewall configuration.
5. **Fail-Fast & Strict Mode**:
   - Script must run under `set -euo pipefail`. Any unhandled failure in package installation or command execution must abort execution immediately.

---

## 🧪 Verification Scenarios (GIVEN / WHEN / THEN)

### Scenario 1: Setup on Debian 13 with GNOME

- **GIVEN** a Debian 13 system (`get_distro_id` returns `debian`) with `XDG_CURRENT_DESKTOP=GNOME` (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `ufw` and `gufw` packages are installed
- **AND** `ufw` is enabled with default incoming deny and outgoing allow rules.

### Scenario 2: Setup on Debian 13 with KDE Plasma

- **GIVEN** a Debian 13 system (`get_distro_id` returns `debian`) with `XDG_CURRENT_DESKTOP=KDE` (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `ufw` and `plasma-firewall` packages are installed
- **AND** `ufw` is enabled and running.

### Scenario 3: Setup on Fedora 44 with GNOME

- **GIVEN** a Fedora 44 system (`get_distro_id` returns `fedora`) with `XDG_CURRENT_DESKTOP=GNOME` (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `firewalld` and `firewall-config` packages are installed
- **AND** `firewalld.service` is enabled.

### Scenario 4: Setup on Fedora 44 with KDE Plasma

- **GIVEN** a Fedora 44 system (`get_distro_id` returns `fedora`) with `XDG_CURRENT_DESKTOP=KDE` (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `firewalld` and `plasma-firewall` packages are installed
- **AND** `firewalld.service` is enabled.

### Scenario 5: Setup on openSUSE with GNOME

- **GIVEN** an openSUSE system (`is_distro opensuse`) with `XDG_CURRENT_DESKTOP=GNOME` (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `firewalld` and `firewall-config` packages are installed
- **AND** `firewalld.service` is enabled.

### Scenario 6: Setup on openSUSE with KDE Plasma

- **GIVEN** an openSUSE system (`is_distro opensuse`) with `XDG_CURRENT_DESKTOP=KDE` (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `firewalld` and `plasma-firewall` (`plasma6-firewall`) packages are installed
- **AND** `firewalld.service` is enabled.

### Scenario 7: Setup on Arch Linux with GNOME

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`) with `XDG_CURRENT_DESKTOP=GNOME` (`get_desktop_environment` returns `gnome`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `ufw` and `gufw` packages are installed
- **AND** `ufw.service` is enabled and started.

### Scenario 8: Setup on Arch Linux with KDE Plasma

- **GIVEN** an Arch Linux system (`get_distro_id` returns `arch`) with `XDG_CURRENT_DESKTOP=KDE` (`get_desktop_environment` returns `plasma`)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** `ufw` and `plasma-firewall` packages are installed
- **AND** `ufw.service` is enabled and started.

### Scenario 9: Setup on Headless / CLI environment (Debian / Fedora / Arch / openSUSE)

- **GIVEN** any supported system (`get_distro_id` returns `debian`, `fedora`, `arch`, or `opensuse*`) with `get_desktop_environment` returning `unknown`
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** the appropriate CLI firewall backend (`ufw` or `firewalld`) is installed and configured
- **AND** no GUI frontends (`gufw` / `firewall-config` / `plasma-firewall`) are installed.

### Scenario 8: Running on an unsupported distribution

- **GIVEN** an unsupported distribution or derivative (`get_distro_id` returns an unsupported ID or fails)
- **WHEN** `scripts/security/setup-firewall.sh` is executed
- **THEN** it SHALL exit with code 1 and write an error message to `stderr`

### Scenario 9: Idempotent Execution

- **GIVEN** any supported system where firewall is already configured
- **WHEN** `scripts/security/setup-firewall.sh` is executed a second time
- **THEN** execution completes with exit code 0 and no error logs.
