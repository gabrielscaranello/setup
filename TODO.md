# 📋 Project Roadmap & Execution Plan (TODO)

This document tracks development milestones, work in progress, and planned features for the Desktop Setup project.

> [!IMPORTANT]
> **Priority Strategy**: All scripts and flows are first prioritized and stabilized for **Arch Linux**, **Fedora**, and **Debian** (fully tested across **GNOME** and **KDE Plasma**). Support for secondary distributions (Linux Mint, LMDE, Ubuntu, openSUSE, Zorin) and the **Cinnamon** desktop environment will only be introduced in Post-v1.0 milestones after the base 3 distros and GNOME/KDE Plasma are fully validated.

## 🎯 Phase 1: Fonts, Terminal & Development / CLI Tools (Immediate Milestone)

Developer runtimes, CLI utilities, and developer fonts (closing the core development toolchain).

- [x] Install JetBrains Mono Nerd Font — `scripts/setup-fonts.sh`
- [x] Install Docker engine and CLI plugins (`buildx`, `compose`) — `scripts/setup-docker.sh`
- [x] Install Gitflow CJS — `scripts/setup-gitflow.sh`
- [x] Install Golang — `scripts/setup-go.sh`
- [x] Install Rust, Cargo, and developer tools (`tree-sitter-cli`) — `scripts/setup-rust.sh`
- [x] Install NVM, Node.js, and global npm packages — `scripts/setup-nvm.sh`
- [x] Build/install Neovim — `scripts/setup-neovim.sh`
- [x] Configure clipboard provider for Neovim (`wl-clipboard` on Arch, `xsel` on Fedora, `xclip` on Debian) — `scripts/setup-neovim.sh`
- [x] Add additional Neovim runtime dependencies across all distros (`imagemagick`, `jq`, `tidy`, `sqlite`, `gettext`, `protobuf-compiler`, `fd` / `fd-find`) — `scripts/setup-neovim.sh`
- [x] Install Kitty terminal emulator — `scripts/setup-kitty.sh`
- [x] Install Lazygit — `scripts/setup-lazygit.sh`
- [x] Install Lazydocker — `scripts/setup-lazydocker.sh`

## ⚙️ Phase 2: Foundation, Kernel, Drivers & Repositories

Prerequisites, kernel backports, graphics drivers, snapshots, and global package sources.

- [x] Base package-manager abstraction (`Debian/apt`, `Fedora/dnf`, `Arch Linux/pacman`) — `scripts/_utils.sh`
- [x] Configure swap settings and memory tuning — `scripts/setup-swap.sh`
- [x] Implement Timeshift installation (Btrfs snapshots on Arch/Fedora, ext4 on Debian) — `scripts/setup-timeshift.sh`
- [x] Implement distribution repository helpers (`scripts/system/debian/_repositories.sh`, `scripts/system/fedora/_repositories.sh`) and backports kernel installation (`scripts/system/debian/setup-kernel.sh`)
- [x] Configure Flatpak and add Flathub remote repository — `scripts/setup-flatpak.sh`
- [x] Configure Firewall (`firewalld` on Fedora; `ufw` on Debian/Arch with `gufw` / `firewall-config` on GNOME, and `plasma-firewall` on KDE Plasma) — `scripts/setup-firewall.sh`
- [ ] Implement NVIDIA graphics drivers installation (including hybrid GPU validation with `envycontrol` for laptops)

## 🔵 Phase 3: Base System Packages & Desktop Environment (DE)

Essential system utilities and base desktop environments for minimal installations.

- [ ] Implement Desktop Environment (DE) installation on Arch Linux (`GNOME`, `KDE Plasma`)
- [ ] Implement core system packages installation (`Debian`, `Arch Linux`, `Fedora` — including `util-linux-user` on Fedora)

## 🔴 Phase 4: Cleanup & Debloat

Removal of unused default packages and bloatware before installing user apps.

- [ ] Implement unused packages removal / debloat script (Debian and Fedora, differentiated for GNOME and KDE Plasma)

## 🟣 Phase 5: GUI Applications & Desktop Tools

General desktop productivity, database management, and gaming software.

- [x] Install Web Browsers (`Chromium`, `Firefox`) — `scripts/apps/setup-browsers.sh`
- [x] Install VSCodium — `scripts/apps/setup-vscodium.sh`
- [x] Install ONLYOFFICE — `scripts/apps/setup-onlyoffice.sh`
- [x] Install Obsidian — `scripts/apps/setup-obsidian.sh`
- [x] Install GIMP — `scripts/apps/setup-gimp.sh`
- [x] Install DBeaver — `scripts/setup-dbeaver.sh`
- [x] Install MongoDB Compass — `scripts/apps/setup-mongodb-compass.sh`
- [ ] Implement VirtualBox installation
- [x] Configure Screenshot Tool (`Flameshot` on GNOME, `Spectacle` on KDE Plasma) — `scripts/apps/setup-screenshot-tool.sh`
- [x] Install Discord — `scripts/setup-discord.sh`
- [x] Install Telegram Desktop — `scripts/setup-telegram.sh`
- [ ] Implement Steam installation (including ProtonUp-Qt / Proton manager, MangoHud, and Gamescope)

## 🎨 Phase 6: Themes, Extensions & Desktop Customization (GNOME & KDE Plasma)

Desktop theming, shell extensions, and interface preferences for target environments.

- [ ] Implement custom cursor theme installation (`GNOME`, `KDE Plasma`)
- [ ] Implement GTK theme installation (`GNOME`)
- [ ] Implement icon theme installation (`GNOME`)
- [ ] Implement GNOME shell extensions installation
- [ ] Implement desktop environment preferences script (`GNOME`, `KDE Plasma`)
- [ ] Implement GNOME extensions configuration script

## 🏁 Phase 7: Final Tweaks & Orchestration

Default application bindings, desktop menu cleanup, and end-to-end execution scripts.

- [-] Implement default applications configuration script (MIME types / protocol handlers) — partially implemented (Kitty terminal emulator) in `scripts/setup-default-apps.sh`
- [ ] Implement script to hide unwanted applications from application menus (`.desktop` files)
- [ ] Create orchestrator scripts (`all.sh` / distro-tailored entrypoints) to run all scripts sequentially

## 🚀 Future Milestones (Post-v1.0)

To be addressed only after Arch Linux, Fedora, and Debian (GNOME + KDE Plasma) are 100% complete and tested.

### 🌐 Secondary Distributions Support

- [ ] Validate and add support for secondary distributions by distro name (Linux Mint, LMDE, Ubuntu, openSUSE Leap, openSUSE Tumbleweed, Zorin OS)

### 🌿 Cinnamon Desktop Environment Support (with Linux Mint & LMDE)

- [ ] Implement Cinnamon applets installation
- [ ] Implement Cinnamon applets configuration script
- [ ] Implement custom cursor and icon themes support for Cinnamon
- [ ] Implement Cinnamon desktop preferences script
