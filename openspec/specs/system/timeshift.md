# Specification: Timeshift Snapshot Provisioning & Boot Integration (`scripts/setup-timeshift.sh`)

## Purpose
Installs and configures Timeshift for automated and on-demand desktop backup snapshots, dynamically generating configuration files based on the root filesystem type (Btrfs vs. RSYNC), integrating `grub-btrfs` / `grub-btrfsd` bootloader menus on Btrfs systems, and creating an initial baseline snapshot.

---

## Requirements

### Requirement: Timeshift Package Installation
The script SHALL install the `timeshift` package across supported distributions via `install_packages timeshift`.

#### Scenario: Installing package
- **GIVEN** a supported distribution (Debian, Fedora, Arch Linux)
- **WHEN** `scripts/setup-timeshift.sh` runs
- **THEN** `timeshift` package SHALL be installed

---

### Requirement: Dynamic Template Rendering & Deployment
The script SHALL inspect the root partition (`/`) filesystem type using `get_root_filesystem` and write the rendered configuration to `/etc/timeshift/timeshift.json`:
- **Btrfs root filesystem**: SHALL deploy `config/timeshift-btrfs.json`.
- **Non-Btrfs (ext4/etc) root filesystem**: SHALL inspect `~/.config/user-dirs.dirs` for `XDG_DOCUMENTS_DIR` (defaulting to `Documents` if unset) and render `config/timeshift-rsync.json` by replacing `:home:` with `$HOME` and `:documents_dir:` with the resolved documents directory name.

#### Scenario: Deploying configuration on Btrfs
- **GIVEN** root partition formatted with Btrfs
- **WHEN** configuration deployment executes
- **THEN** `/etc/timeshift/timeshift.json` SHALL match `config/timeshift-btrfs.json`

#### Scenario: Deploying configuration on ext4
- **GIVEN** root partition formatted with ext4 and user documents directory resolved
- **WHEN** configuration deployment executes
- **THEN** `/etc/timeshift/timeshift.json` SHALL contain RSYNC snapshot settings with the user's home path substituted

---

### Requirement: `grub-btrfs` Installation & Bootloader Integration (Btrfs Only)
When the root filesystem is `btrfs`, the script SHALL configure GRUB bootloader snapshot integration:
- **Dependencies**: SHALL install `btrfs-progs`, `gawk`, and `inotify-tools`.
- **Arch Linux (`pacman`)**: SHALL install `grub-btrfs` directly via package manager.
- **Fedora (`dnf`) & Debian (`apt`)**: SHALL clone `https://github.com/Antynea/grub-btrfs.git` to `/tmp/grub-btrfs`, configure Fedora-specific GRUB paths (`GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig`, `GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"`, `GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check`) when running on `dnf`, run `make install`, clean up `/tmp/grub-btrfs`, and execute `systemctl daemon-reload`.

#### Scenario: Running on Btrfs on Arch Linux
- **GIVEN** Arch Linux with Btrfs root
- **WHEN** boot integration executes
- **THEN** `grub-btrfs` package is installed from repository

#### Scenario: Running on Btrfs on Fedora or Debian
- **GIVEN** Fedora or Debian with Btrfs root
- **WHEN** boot integration executes
- **THEN** `grub-btrfs` is built and installed from upstream Git repository with paths tailored to the active distribution

#### Scenario: Running on non-Btrfs (ext4) filesystem
- **GIVEN** non-Btrfs root filesystem
- **WHEN** boot integration executes
- **THEN** `grub-btrfs` installation and daemon setup SHALL be completely bypassed

---

### Requirement: `grub-btrfsd` Service Configuration & GRUB Menu Regeneration
When on a Btrfs filesystem with systemd:
- **Service Patch**: SHALL locate `grub-btrfsd.service` via `systemctl show -p FragmentPath grub-btrfsd.service` and patch `ExecStart` to `/usr/bin/grub-btrfsd --syslog --timeshift-auto`.
- **Service Enablement**: SHALL reload systemd daemon and enable/start `grub-btrfsd.service` (`systemctl enable --now grub-btrfsd.service`).
- **GRUB Menu Update**: If `/etc/grub.d/41_snapshots-btrfs` is executable, it SHALL execute it and regenerate GRUB configuration using the first available tool: `grub2-mkconfig -o /boot/grub2/grub.cfg`, `grub-mkconfig -o /boot/grub/grub.cfg`, or `update-grub`.

#### Scenario: Enabling daemon and updating GRUB
- **GIVEN** `grub-btrfsd.service` exists on a Btrfs system
- **WHEN** service setup executes
- **THEN** service file has `--syslog --timeshift-auto` flags and service is enabled and started
- **AND** GRUB snapshot menu is regenerated

---

### Requirement: Initial Baseline Snapshot
The script SHALL create an initial baseline snapshot if `timeshift` binary is present: `sudo timeshift --create --comments "Initial setup snapshot" --tags D --scripted`.

#### Scenario: Creating baseline snapshot
- **GIVEN** Timeshift configuration deployed
- **WHEN** setup finishes
- **THEN** an initial on-demand daily snapshot is created non-interactively
