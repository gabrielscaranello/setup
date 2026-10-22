# 🪟 WSL Installation & Provisioning Guide (Debian 13)

🇧🇷 **Documentação em Português (BR):** [wsl-pt-br.md](wsl-pt-br.md)

This guide covers the complete step-by-step setup—based on the **official Microsoft WSL documentation**—to install and configure **WSL 3** with **Debian 13 Trixie**, **JetBrains Mono Nerd Font**, and a **`ext4` `.vhdx` persistent disk automatically mounting the entire `$HOME` directory** before running `./main.sh wsl` (or `make all`).

---

## 1. Install and Update the WSL Engine (WSL 3)

Open **PowerShell as Administrator** on Windows 11:

```powershell
# 1. Install/update the WSL engine to the latest release (WSL 3.x)
wsl --install --no-distribution
wsl --update

# 2. Ensure the virtual machine architecture (generation 2) is the default
wsl --set-default-version 2

# 3. Verify the installed version (should display WSL version: 3.x.x)
wsl --version
```

> [!NOTE]
> **Why does `wsl --version` show `3.x` while `--set-default-version` uses `2`?**
> The Microsoft Store WSL package is now on **version 3 (`3.0.x`)**, whereas `--set-default-version` selects the execution architecture generation (`1` = legacy syscall translation layer vs. `2` = lightweight Hyper-V virtual machine used by WSL 3). If this is the first time enabling WSL on the machine, reboot Windows when prompted.

---

## 2. Install JetBrains Mono Nerd Font on Windows

In WSL, terminal text and icons are rendered by **Windows Terminal** on the Windows host. For Neovim, Lazygit, Lazydocker, `eza`, and Zsh icons to display properly, the font must be installed **on Windows**:

### 2.1. Install via `winget` in PowerShell

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont -e
```

### 2.2. Enable in Windows Terminal

1. Open **Windows Terminal** and press `Ctrl + ,` to open **Settings**.
2. In the left sidebar under **Profiles**, click **Defaults** -> **Appearance**.
3. Under **Font face**, select **`JetBrainsMono Nerd Font`** (or `JetBrainsMono NF`) and click **Save**.

_(Alternatively, press `Ctrl + Shift + ,` to open Windows Terminal's `settings.json` and add `"font": { "face": "JetBrainsMono Nerd Font" }` inside `"profiles": { "defaults": { ... } }`)._

> [!TIP]
> If you also run Linux GUI applications via **WSLg**, you can install the font inside the Linux filesystem by running `./main.sh fonts`.

---

## 3. Install Official Debian 13 (Trixie)

**Debian** (`Debian`) is available directly in the official Microsoft WSL distribution manifest (`wsl --list --online`):

```powershell
# Verify available official distributions:
wsl --list --online

# Install official Debian 13 Trixie and set it as the default distribution
wsl --install -d Debian
wsl --set-default Debian
```

On first launch, the Debian installer will prompt you to create your default user (UID `1000`) and password.

---

## 4. Persistent `.vhdx` `ext4` Workspace Disk with Auto-Mount (Windows 11 Home, Pro & Enterprise)

To ensure your entire user directory (`$HOME` — including repositories, SSH keys, dotfiles, Zsh history, and user-scoped toolchains) survives even if the distribution is recreated (`wsl --unregister Debian`), create a dedicated `.vhdx` virtual disk formatted as `ext4` using `wsl --mount --vhd`.

### 4.1. Create and Attach the `.vhdx` in PowerShell (Administrator)

The command below uses Windows' built-in **`diskpart`** utility, which works natively on **both Windows 11 Home and Windows 11 Pro / Enterprise**:

```powershell
# 1. Create directory to store the persistent virtual disk
New-Item -ItemType Directory -Force -Path "C:\WSL"

# 2. Create a dynamic (expandable) 100 GB VHDX via diskpart (works on Windows 11 Home & Pro)
@"
create vdisk file="C:\WSL\workspace-data.vhdx" maximum=102400 type=expandable
exit
"@ | diskpart

# 3. Attach the VHDX to WSL without mounting partitions yet (--bare)
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --bare
```

_(Note: On Windows 11 Pro/Enterprise editions with the Hyper-V PowerShell module enabled, `New-VHD -Path "C:\WSL\workspace-data.vhdx" -SizeBytes 100GB -Dynamic` produces the same result)._

### 4.2. Format as `ext4` (One-Time Setup Inside Debian)

Open Debian (`wsl -d Debian`):

```bash
# Identify the unformatted 100G disk device (typically /dev/sdc or /dev/sdd)
lsblk

# Format as ext4 with the "workspace" label
sudo mkfs.ext4 -L workspace /dev/sdX
```

Exit Debian (`exit`) and mount the disk officially under the name `workspace` from PowerShell (Administrator):

```powershell
wsl --unmount "C:\WSL\workspace-data.vhdx"
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace
```

### 4.3. Configure Persistent Auto-Mount on Windows

By default in WSL, disks attached via `wsl --mount --vhd` are detached whenever the WSL VM stops (which happens 8 seconds after closing all terminal windows or after `wsl --shutdown`). To ensure `/mnt/wsl/workspace` **always stays mounted automatically**:

In **PowerShell (Administrator)**, run:

```powershell
# 1. Prevent the WSL VM from shutting down automatically on idle after closing terminals (vmIdleTimeout=-1)
@"
[wsl2]
vmIdleTimeout=-1
"@ | Set-Content -Encoding UTF8 "$env:USERPROFILE\.wslconfig"

# 2. Register a Scheduled Task with highest privileges to mount the VHDX at Windows logon and on demand
$action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument '--mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "WSL-Mount-Workspace" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

# 3. Run the task immediately to verify
Start-ScheduledTask -TaskName "WSL-Mount-Workspace"
```

---

## 5. Debian 13 Configuration (`systemd`, `zsh`, and Full `$HOME` Bind-Mount)

By combining the `WSL-Mount-Workspace` Scheduled Task with the `[boot] command` hook in `/etc/wsl.conf` below:

1. **Even if you run `wsl --shutdown` or `wsl --terminate`**, Debian will automatically trigger the Windows task on boot and wait for `/mnt/wsl/workspace` to be mounted.
2. It will then **`mount --bind` `/mnt/wsl/workspace/home/$USER` directly over `/home/$USER`** before opening your shell—requiring no manual symlinks.

Inside Debian (`wsl -d Debian`), run:

```bash
# 1. Install git, curl, ca-certificates, zsh, and mount
sudo apt update && sudo apt install -y git curl ca-certificates zsh mount

# 2. Set Zsh as the default login shell so PATH exports target ~/.zshrc
sudo chsh -s /usr/bin/zsh "$USER"

# 3. Configure /etc/wsl.conf (native systemd + default user + VHDX auto-mount & full $HOME bind-mount)
sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true
command="/bin/sh -c 'if ! mountpoint -q /mnt/wsl/workspace; then /mnt/c/Windows/System32/schtasks.exe /run /tn WSL-Mount-Workspace >/dev/null 2>&1 || true; for i in 1 2 3 4 5; do mountpoint -q /mnt/wsl/workspace && break; sleep 1; done; fi; if mountpoint -q /mnt/wsl/workspace && ! mountpoint -q /home/$USER; then mkdir -p /mnt/wsl/workspace/home/$USER && cp -rn /home/$USER/. /mnt/wsl/workspace/home/$USER/ && chown -R 1000:1000 /mnt/wsl/workspace/home/$USER && mount --bind /mnt/wsl/workspace/home/$USER /home/$USER; fi'"

[user]
default=$USER
EOF
```

Exit Debian (`exit`) and restart the instance in PowerShell:

```powershell
wsl --terminate Debian
```

When you reopen Debian (`wsl`), your entire `$HOME` (`/home/$USER`) will be mounted directly from the persistent `.vhdx` disk (verify with `df -h ~`).

---

## 6. Running the WSL Setup Pipeline (`runners/wsl.sh`)

With your `$HOME` mounted on the `.vhdx`, clone this repository and run the setup:

```bash
mkdir -p ~/Code/Github
cd ~/Code/Github
git clone https://github.com/gabrielscaranello/setup.git
cd setup

# Run the full WSL development pipeline (or `make all`, which auto-detects WSL)
./main.sh wsl
```

### What `./main.sh wsl` (or `make all` on WSL) provisions:

1. **`system/setup-update.sh`**: Refreshes repository metadata and upgrades all installed packages (`apt update && apt upgrade`).
2. **`terminal/setup-cli.sh`**: Installs `bat` (with `batcat -> ~/.local/bin/bat` symlink), `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `openssh`, `dialog`, `keychain`, and `wl-clipboard` (integrated with the Windows clipboard via WSLg Wayland socket).
3. **`toolchain/setup-docker.sh`**: Installs Docker Engine, `docker-compose`, `docker-buildx`, enables `docker.service` via `systemd`, and adds your user to the `docker` group.
4. **`toolchain/setup-gitflow.sh`**: Installs Gitflow CJS.
5. **`toolchain/setup-gh.sh`**: Installs the native GitHub CLI (`gh`) package in Debian WSL.
6. **`toolchain/setup-python.sh`**: Installs `python3`, `pip`, and `venv`.
7. **`toolchain/setup-go.sh`**: Installs Golang and `dockerfmt`, configuring `GOPATH` and `PATH` in your shell profile.
8. **`toolchain/setup-nvm.sh`**: Installs NVM, Node.js 24, enables Corepack (`yarn`), and installs global npm packages (`@github/copilot`, `@styled/typescript-styled-plugin`).
9. **`terminal/setup-lazygit.sh` & `terminal/setup-lazydocker.sh`**: Installs Lazygit and Lazydocker.
10. **`toolchain/setup-neovim.sh`**: Automatically provisions Rust/Cargo + `tree-sitter-cli`, Neovim runtime dependencies (`ripgrep`, `fd`, `luarocks`, `jq`, `sqlite`, `imagemagick`, `tidy`, `protobuf`), and builds/installs Neovim from the `stable` branch (`.deb`).
