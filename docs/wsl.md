# 🪟 WSL2 Installation & Provisioning Guide

🇧🇷 **Documentação em Português (BR):** [wsl-pt-br.md](wsl-pt-br.md)

This guide covers the complete step-by-step setup—based on the **official Microsoft WSL2 documentation** and the **ArchWiki (Official Arch Linux WSL image)**—to install and configure WSL2 with **Arch Linux** (primary distro), **Debian 13 Trixie** (fallback distro), and a shared **`ext4` `.vhdx` persistent disk** before running `./main.sh wsl` (or `make all`).

---

## 1. Install and Update the WSL2 Engine (Windows)

Open **PowerShell as Administrator** on Windows 11 (or Windows 10 22H2+):

```powershell
# 1. Install/update the WSL2 engine (Microsoft Store version with systemd, WSLg, and --vhd support)
wsl --install --no-distribution
wsl --update

# 2. Ensure WSL 2 is the default version for all distributions
wsl --set-default-version 2
```

> [!NOTE]
> If this is the first time enabling WSL on the machine, reboot Windows when prompted before proceeding.

---

## 2. Install Official Distributions (Arch Linux + Debian 13)

Both **Arch Linux** (`archlinux`) and **Debian** (`Debian`) are available directly in the official Microsoft WSL distribution manifest (`wsl --list --online`):

```powershell
# Verify available official distributions:
wsl --list --online

# 1. Install official Arch Linux (Primary Distro)
wsl --install archlinux

# 2. Install official Debian 13 Trixie (Fallback Distro)
wsl --install -d Debian

# Set Arch Linux as the default distribution when running `wsl`
wsl --set-default archlinux
```

---

## 3. Initial User, `sudo`, and `systemd` Configuration

The setup scripts in this repository (`setup-docker.sh`, `setup-cli.sh`, `setup-neovim.sh`, etc.) require:

- A regular (non-root) user with `sudo` privileges (`scripts/_utils.sh` and service/package helpers).
- `systemd=true` enabled in `/etc/wsl.conf` (required for `systemctl enable/start docker.service` in `scripts/toolchain/setup-docker.sh`).
- `git` and `sudo` installed (`README.md` prerequisites).

### 3.1. Arch Linux (`wsl -d archlinux`)

The official `archlinux` WSL image boots as `root` on first launch. Run inside Arch Linux:

```bash
# 1. Initialize pacman keyring and install sudo, git, and zsh
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm sudo git zsh

# 2. Create your regular user with UID 1000 (matching Debian) and Zsh as default login shell
useradd -m -u 1000 -G wheel -s /usr/bin/zsh gabriel
passwd gabriel

# 3. Grant sudo privileges to the wheel group
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# 4. Configure /etc/wsl.conf (default user + native systemd)
cat << 'EOF' > /etc/wsl.conf
[boot]
systemd=true

[user]
default=gabriel
EOF
```

Exit Arch (`exit`) and restart the instance from PowerShell:

```powershell
wsl --terminate archlinux
```

### 3.2. Debian 13 (`wsl -d Debian`)

The official Debian WSL installer prompts you to create your default user (UID `1000`) and password on first boot. Afterwards, install `git`, `curl`, and `zsh`, and ensure `systemd=true` is configured in `/etc/wsl.conf`:

```bash
# 1. Install git, curl, ca-certificates, and zsh
sudo apt update && sudo apt install -y git curl ca-certificates zsh

# 2. (Optional) Set Zsh as the default login shell so PATH exports target ~/.zshrc
sudo chsh -s /usr/bin/zsh "$USER"

# 3. Enable systemd and set default user in /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true

[user]
default=$USER
EOF
```

Exit Debian (`exit`) and restart the instance from PowerShell:

```powershell
wsl --terminate Debian
```

---

## 4. Persistent `.vhdx` `ext4` Workspace Disk (Shared Across Distros)

To ensure your repositories, SSH keys, and workspace survive even if a WSL distribution is recreated (`wsl --unregister archlinux`), create a dedicated `.vhdx` virtual disk formatted as `ext4` using `wsl --mount --vhd`:

### 4.1. Create and Attach the `.vhdx` in PowerShell (Administrator)

```powershell
# Create directory to store the persistent virtual disk
New-Item -ItemType Directory -Force -Path "C:\WSL"

# Create a dynamic 100 GB VHDX (only consumes actual used space on the host SSD)
New-VHD -Path "C:\WSL\workspace-data.vhdx" -SizeBytes 100GB -Dynamic

# Attach the VHDX to WSL2 without mounting partitions yet (--bare)
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --bare
```

### 4.2. Format as `ext4` (One-Time Setup Inside Arch or Debian)

Open Arch Linux (`wsl -d archlinux`):

```bash
# Identify the unformatted 100G disk device (typically /dev/sdc or /dev/sdd)
lsblk

# Format as ext4 with the "workspace" label
sudo mkfs.ext4 -L workspace /dev/sdX
```

### 4.3. Mount and Share Between Arch Linux and Debian 13

In PowerShell (Administrator):

```powershell
# Unmount the --bare attachment and mount officially with the name "workspace"
wsl --unmount "C:\WSL\workspace-data.vhdx"
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace
```

Per official Microsoft WSL documentation, any disk mounted via `wsl --mount --name workspace` is automatically accessible at **`/mnt/wsl/workspace`** across **all running WSL2 distributions simultaneously** (both Arch Linux and Debian 13).

Inside Arch Linux (`wsl -d archlinux`), set ownership to UID `1000` and create your persistent directories:

```bash
sudo chown -R 1000:1000 /mnt/wsl/workspace
mkdir -p /mnt/wsl/workspace/{Code,.ssh}
chmod 700 /mnt/wsl/workspace/.ssh

# Create symlinks in $HOME (repeat these two ln -sfn commands inside Debian as well):
ln -sfn /mnt/wsl/workspace/Code ~/Code
ln -sfn /mnt/wsl/workspace/.ssh ~/.ssh
```

---

## 5. Running the WSL Setup Pipeline (`runners/wsl.sh`)

Clone this repository into your persistent workspace and run the setup:

```bash
mkdir -p ~/Code/Github
cd ~/Code/Github
git clone https://github.com/gabrielscaranello/setup.git
cd setup

# Run the full WSL development pipeline (or `make all`, which auto-detects WSL2)
./main.sh wsl
```

### What `./main.sh wsl` (or `make all` on WSL) provisions:

1. **`system/setup-update.sh`**: Refreshes repository metadata and upgrades all installed packages (`pacman -Syu` on Arch or `apt update && apt upgrade` on Debian 13).
2. **`terminal/setup-cli.sh`**: Installs `bat` (with `batcat -> ~/.local/bin/bat` symlink on Debian), `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `openssh`, `dialog`, `keychain`, and `wl-clipboard` (integrated with the Windows clipboard via WSLg Wayland socket).
3. **`toolchain/setup-docker.sh`**: Installs Docker Engine, `docker-compose`, `docker-buildx`, enables `docker.service` via `systemd`, and adds your user to the `docker` group.
4. **`toolchain/setup-gitflow.sh`**: Installs Gitflow CJS.
5. **`toolchain/setup-gh.sh`**: Installs the native GitHub CLI (`gh`) package in WSL environments.
6. **`toolchain/setup-python.sh`**: Installs `python3`, `pip`, and `venv`.
7. **`toolchain/setup-go.sh`**: Installs Golang and `dockerfmt`, configuring `GOPATH` and `PATH` in your shell profile.
8. **`toolchain/setup-nvm.sh`**: Installs NVM, Node.js 24, enables Corepack (`yarn`), and installs global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`).
9. **`terminal/setup-lazygit.sh` & `terminal/setup-lazydocker.sh`**: Installs Lazygit and Lazydocker.
10. **`toolchain/setup-neovim.sh`**: Automatically provisions Rust/Cargo + `tree-sitter-cli`, Neovim runtime dependencies (`ripgrep`, `fd`, `luarocks`, `jq`, `sqlite`, `imagemagick`, `tidy`, `protobuf`), and Neovim (`pacman` package on Arch or built from the `stable` branch `.deb` on Debian 13).
