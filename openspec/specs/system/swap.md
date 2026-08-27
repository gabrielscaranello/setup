# Specification: Swap, ZRAM & Memory Tuning (`scripts/setup-swap.sh`)

## Purpose
Optimizes Linux memory management for interactive desktop performance by tuning virtual memory sysctl parameters, configuring compressed RAM swap (ZRAM) dynamically per distribution, and safely provisioning a root filesystem-aware persistent swapfile (Btrfs vs. standard filesystems) with fallback mechanisms.

---

## Requirements

### Requirement: Sysctl Virtual Memory Tuning
The script SHALL create `/etc/sysctl.d/00-custom.conf` and apply VM parameters immediately:
- `vm.swappiness=10`
- `vm.vfs_cache_pressure=50`
- Execution of `sysctl -p /etc/sysctl.d/00-custom.conf` (or `sysctl --system`).

#### Scenario: Applying sysctl configuration
- **GIVEN** a Linux system
- **WHEN** `scripts/setup-swap.sh` is executed
- **THEN** `/etc/sysctl.d/00-custom.conf` SHALL contain swappiness and cache pressure settings
- **AND** settings SHALL be loaded into the running kernel without requiring a reboot

---

### Requirement: ZRAM Configuration by Distribution
The script SHALL install the appropriate `zram` package and configure compressed RAM swap equal to half of total RAM (`RAM / 2`, compression `zstd`, priority `100`):
- **Debian (`apt`)**: SHALL configure `/etc/default/zramswap` with `ALGO=zstd`, `PERCENT=50`, `PRIORITY=100`, and restart `zramswap.service`.
- **Fedora (`dnf`) & Arch Linux (`pacman`)**: SHALL configure `/etc/systemd/zram-generator.conf` under `[zram0]` (`zram-size = ram / 2`, `compression-algorithm = zstd`, `swap-priority = 100`), reload systemd daemon, and restart `systemd-zram-setup@zram0.service` / start `/dev/zram0`.

#### Scenario: Running on Debian
- **GIVEN** a Debian system with `apt`
- **WHEN** `scripts/setup-swap.sh` runs
- **THEN** `zram-tools` is configured via `/etc/default/zramswap` and service restarted

#### Scenario: Running on Fedora or Arch Linux
- **GIVEN** a Fedora or Arch Linux system with `dnf` or `pacman`
- **WHEN** `scripts/setup-swap.sh` runs
- **THEN** `/etc/systemd/zram-generator.conf` is written and zram generator service triggered

---

### Requirement: Dynamic Swap Size Calculation
The script SHALL calculate swapfile size dynamically from `/proc/meminfo` (`MemTotal`):
- Size = `MemTotal / 1024 / 1024 / 2` (half of total RAM in GB).
- If calculated size is less than 4GB (or if `MemTotal` cannot be read), size SHALL default to a minimum of **4GB**.

#### Scenario: System with 16GB RAM
- **GIVEN** a system with 16GB of physical RAM
- **WHEN** swapfile size is calculated
- **THEN** size SHALL be 8GB

#### Scenario: System with 4GB RAM or lower
- **GIVEN** a system with 4GB or 2GB of physical RAM
- **WHEN** swapfile size is calculated
- **THEN** size SHALL be clamped to the minimum 4GB

---

### Requirement: Filesystem-Aware Swapfile Provisioning & Fallbacks
The script SHALL check if `/swapfile` is already active via `swapon --show=NAME`:
- If already active, swapfile creation and formatting SHALL be skipped.
- If not active, any old `/swapfile` SHALL be turned off (`swapoff`) and removed before creating a new one.

#### Scenario: Swapfile on Btrfs filesystem
- **GIVEN** the root partition filesystem is `btrfs`
- **WHEN** swapfile creation runs
- **THEN** it SHALL attempt creation using `btrfs filesystem mkswapfile --size <size>G /swapfile`
- **AND** if `btrfs filesystem mkswapfile` fails or is unavailable, it SHALL execute fallback:
  1. `truncate -s 0 /swapfile`
  2. `chattr +C /swapfile` (disable Copy-on-Write)
  3. `btrfs property set /swapfile compression none` (disable compression)
  4. `dd if=/dev/zero of=/swapfile bs=1G count=<size>` (or `fallocate`)
  5. `chmod 0600 /swapfile` and `mkswap /swapfile`

#### Scenario: Swapfile on Standard filesystems (ext4, xfs)
- **GIVEN** the root partition filesystem is `ext4` or other non-Btrfs filesystem
- **WHEN** swapfile creation runs
- **THEN** it SHALL attempt fast allocation using `fallocate -l <size>G /swapfile`
- **AND** if `fallocate` fails, it SHALL fall back to `dd if=/dev/zero of=/swapfile bs=1M count=<size_in_mb>`
- **AND** set permissions to `0600` and format with `mkswap /swapfile`

---

### Requirement: Swap Activation & `/etc/fstab` Persistence
The script SHALL activate the created `/swapfile` using `swapon /swapfile` and ensure `/swapfile none swap sw 0 0` is appended to `/etc/fstab` if not already present.

#### Scenario: Checking fstab persistence
- **GIVEN** `/swapfile` created and `/etc/fstab` exists
- **WHEN** swap persistence check executes
- **THEN** `/swapfile none swap sw 0 0` is added to `/etc/fstab` without duplicating existing entries
