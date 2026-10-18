# 📋 Project Roadmap & Execution Plan (TODO)

Este documento acompanha os marcos de desenvolvimento, tarefas em andamento e funcionalidades planejadas para o projeto Desktop Setup.

---

## 🏆 Milestone 1.0: Arch Linux, Fedora & Debian (GNOME & KDE Plasma) [Concluído]

<details>
<summary><b>Clique para ver as fases concluídas do Milestone 1.0</b></summary>

### Phase 1: Fonts, Terminal & Development / CLI Tools

- [x] Install JetBrains Mono Nerd Font — `scripts/terminal/setup-fonts.sh`
- [x] Install Docker engine and CLI plugins (`buildx`, `compose`) — `scripts/toolchain/setup-docker.sh`
- [x] Install Gitflow CJS — `scripts/toolchain/setup-gitflow.sh`
- [x] Install Golang — `scripts/toolchain/setup-go.sh`
- [x] Install Rust, Cargo, and developer tools (`tree-sitter-cli`) — `scripts/toolchain/setup-rust.sh`
- [x] Install NVM, Node.js, and global npm packages — `scripts/toolchain/setup-nvm.sh`
- [x] Build/install Neovim — `scripts/toolchain/setup-neovim.sh`
- [x] Configure clipboard provider for Neovim (`wl-clipboard` on Arch, `xsel` on Fedora, `xclip` on Debian) — `scripts/toolchain/setup-neovim.sh`
- [x] Add additional Neovim runtime dependencies across all distros (`imagemagick`, `jq`, `tidy`, `sqlite`, `gettext`, `protobuf-compiler`, `fd` / `fd-find`) — `scripts/toolchain/setup-neovim.sh`
- [x] Install Kitty terminal emulator — `scripts/terminal/setup-kitty.sh`
- [x] Install Lazygit — `scripts/terminal/setup-lazygit.sh`
- [x] Install Lazydocker — `scripts/terminal/setup-lazydocker.sh`

### Phase 2: Foundation, Kernel, Drivers & Repositories

- [x] Base distribution and package-manager abstraction (`get_distro_id`, `packages.conf`) — `scripts/_utils.sh`
- [x] Configure swap settings and memory tuning — `scripts/system/setup-swap.sh`
- [x] Implement Timeshift installation (Btrfs snapshots on Arch/Fedora, ext4 on Debian) — `scripts/system/setup-timeshift.sh`
- [x] Implement distribution repository helpers (`scripts/system/debian/_repositories.sh`, `scripts/system/fedora/_repositories.sh`, `scripts/system/arch/_repositories.sh`) and backports kernel installation (`scripts/system/debian/setup-kernel.sh`)
- [x] Configure Flatpak and add Flathub remote repository — `scripts/system/setup-flatpak.sh`
- [x] Configure Firewall (`firewalld` on Fedora; `ufw` on Debian/Arch with `gufw` / `firewall-config` on GNOME, and `plasma-firewall` on KDE Plasma) — `scripts/security/setup-firewall.sh`
- [x] Install NVIDIA graphics drivers and hybrid GPU tools (Debian backports, `switcheroo-control` & `prime-run`) — `scripts/system/setup-nvidia.sh`
- [x] Configure AMD graphics packages, firmware and codecs — `scripts/system/setup-amd.sh`
- [x] Implement graphics drivers orchestrator (`graphics`) — `scripts/system/setup-graphics.sh`
- [x] Install multimedia codecs and audio/video plugins across all distros — `scripts/system/setup-codecs.sh`

### Phase 3: Base System Packages & Desktop Environment (DE)

- [x] Implement Desktop Environment (DE) installation on Arch Linux (`GNOME`, `KDE Plasma`) — `scripts/system/arch/setup-desktop-environment.sh`
- [x] Implement core system packages installation (`Debian`, `Arch Linux`, `Fedora`) — `scripts/system/setup-packages.sh`
- [x] Implement curated Desktop Environment applications suite (`GNOME`, `KDE Plasma`) — `scripts/desktop/setup-desktop-apps.sh`

### Phase 4: Cleanup & Debloat

- [x] Implement unused packages removal / debloat script (Debian and Fedora, differentiated for GNOME and KDE Plasma) — `scripts/system/setup-debloat.sh`
- [x] Implement system update and upgrade script — `scripts/system/setup-update.sh`

### Phase 5: GUI Applications & Desktop Tools

- [x] Install Web Browsers (`Chromium`, `Firefox`) — `scripts/apps/setup-browsers.sh`
- [x] Install VSCodium — `scripts/apps/setup-vscodium.sh`
- [x] Install ONLYOFFICE — `scripts/apps/setup-onlyoffice.sh`
- [x] Install Obsidian — `scripts/apps/setup-obsidian.sh`
- [x] Install GIMP — `scripts/apps/setup-gimp.sh`
- [x] Install DBeaver — `scripts/apps/setup-dbeaver.sh`
- [x] Install MongoDB Compass — `scripts/apps/setup-mongodb-compass.sh`
- [x] Configure Screenshot Tool (`Flameshot` on GNOME, `Spectacle` on KDE Plasma) — `scripts/apps/setup-screenshot-tool.sh`
- [x] Install Discord — `scripts/apps/setup-discord.sh`
- [x] Install Telegram Desktop — `scripts/apps/setup-telegram.sh`
- [x] Install Steam and gaming tools — `scripts/apps/setup-steam.sh`

### Phase 6: Themes, Extensions & Desktop Customization (GNOME & KDE Plasma)

- [x] Implement custom cursor theme installation (`GNOME`, `KDE Plasma`) — `scripts/desktop/setup-cursor-theme.sh`
- [x] Implement GTK theme installation (`GNOME`) — `scripts/desktop/setup-gtk-theme.sh`
- [x] Implement icon theme installation (`GNOME`) — `scripts/desktop/setup-icon-theme.sh`
- [x] Implement desktop appearance orchestrator (`look`) — `scripts/desktop/setup-look.sh`
- [x] Implement GNOME shell extensions installation — `scripts/desktop/setup-gnome-extensions.sh`
- [x] Implement desktop environment preferences script (`GNOME`, `KDE Plasma`) — `scripts/desktop/setup-desktop-preferences.sh`
- [x] Implement GNOME extensions configuration script — `scripts/desktop/setup-gnome-extensions-config.sh`

### Phase 7: Final Tweaks & Orchestration

- [x] Implement default applications configuration script (MIME types / protocol handlers) — `scripts/apps/setup-default-apps.sh`
- [x] Implement script to hide unwanted applications from application menus (`.desktop` files) — `scripts/desktop/setup-hide-apps.sh`
- [x] Create orchestrator scripts (`all.sh` / distro-tailored entrypoints) — `main.sh`, `runners/main.sh`, and `runners/{arch,debian,fedora}.sh`

</details>

---

## 🦎 Milestone 2.0: openSUSE Leap 16.1 & openSUSE Tumbleweed (GNOME & KDE Plasma) [Planned]

Implementation roadmap for full openSUSE Leap 16.1 and openSUSE Tumbleweed support across both **GNOME** and **KDE Plasma** desktop environments.

### Phase 1: Foundation & Package Manager Abstraction (`zypper`)

- [x] Add openSUSE distribution detection in `scripts/_utils.sh` (`opensuse-leap`, `opensuse-tumbleweed`, `get_distro_id`) — `scripts/utils/_system.sh`
- [x] Implement package manager adapter for `zypper` (`zypper --non-interactive install --no-recommends`) — `scripts/utils/_packages.sh`
- [x] Map openSUSE packages in `scripts/packages.conf` across system, CLI, and GUI tools — `scripts/packages.conf`
- [x] Implement openSUSE repository helper (`scripts/system/opensuse/_repositories.sh`) with Packman repository support — `scripts/system/opensuse/_repositories.sh`

### Phase 2: System, Drivers, Kernel & Security

- [x] Configure swap settings and memory tuning on openSUSE — `scripts/system/setup-swap.sh`
- [x] Configure Btrfs integration with Snapper / Timeshift — `scripts/system/setup-timeshift.sh`
- [x] Configure Firewall (`firewalld` with `plasma-firewall` on KDE Plasma and `firewall-config` on GNOME) — `scripts/security/setup-firewall.sh`
- [x] Configure NVIDIA graphics drivers (openSUSE official NVIDIA repository) and AMD — `scripts/system/setup-nvidia.sh`, `scripts/system/setup-amd.sh`, `scripts/system/setup-graphics.sh`
- [x] Install multimedia codecs via Packman repository — `scripts/system/setup-codecs.sh`
- [x] Configure Flatpak and Flathub on openSUSE — `scripts/system/setup-flatpak.sh`

### Phase 3: Development Toolchain & Terminal

- [x] Install JetBrains Mono Nerd Font — `scripts/terminal/setup-fonts.sh`
- [x] Install Kitty terminal emulator — `scripts/terminal/setup-kitty.sh`
- [x] Install Docker engine and plugins (`docker`, `docker-compose`) via Zypper — `scripts/toolchain/setup-docker.sh`
- [x] Install Gitflow CJS, Golang, Rust/Cargo, NVM/Node.js — `scripts/toolchain/setup-*.sh`
- [x] Install/build Neovim with Zypper runtime dependencies (`wl-clipboard`, `xclip`, `xsel`) — `scripts/toolchain/setup-neovim.sh`
- [ ] Install Lazygit and Lazydocker binaries — `scripts/terminal/setup-lazygit.sh`, `scripts/terminal/setup-lazydocker.sh`

### Phase 4: Base System Packages & Desktop Environments (GNOME & KDE Plasma)

- [ ] Install base system packages on openSUSE Leap 16.1 and Tumbleweed — `scripts/system/setup-packages.sh`
- [ ] Install curated Desktop Environment applications suite (`GNOME`, `KDE Plasma`) — `scripts/desktop/setup-desktop-apps.sh`
- [ ] Implement unused packages cleanup / debloat on openSUSE for GNOME and KDE — `scripts/system/setup-debloat.sh`
- [ ] Implement system update script (`zypper dup` on Tumbleweed, `zypper up` on Leap) — `scripts/system/setup-update.sh`

### Phase 5: GUI Applications & Desktop Tools

- [ ] Install Web Browsers (`Chromium`, `Firefox`) — `scripts/apps/setup-browsers.sh`
- [ ] Install VSCodium (RPM/YUM repository via Zypper) — `scripts/apps/setup-vscodium.sh`
- [ ] Install ONLYOFFICE, Obsidian, GIMP, DBeaver, MongoDB Compass — `scripts/apps/setup-*.sh`
- [ ] Configure screenshot tool (`Flameshot` on GNOME, `Spectacle` on KDE Plasma) — `scripts/apps/setup-screenshot-tool.sh`
- [ ] Install Discord and Telegram Desktop — `scripts/apps/setup-discord.sh`, `scripts/apps/setup-telegram.sh`
- [ ] Install Steam and gaming tools — `scripts/apps/setup-steam.sh`

### Phase 6: Themes, Extensions & Desktop Customization (GNOME & KDE Plasma)

- [ ] Configure Bibata cursor theme (`GNOME`, `KDE Plasma`) — `scripts/desktop/setup-cursor-theme.sh`
- [ ] Configure GTK theme (`adw-gtk3-dark`) and Papirus icons on GNOME — `scripts/desktop/setup-gtk-theme.sh`, `scripts/desktop/setup-icon-theme.sh`
- [ ] Appearance orchestrator (`look`) — `scripts/desktop/setup-look.sh`
- [ ] Install and configure GNOME Shell extensions — `scripts/desktop/setup-gnome-extensions.sh`, `scripts/desktop/setup-gnome-extensions-config.sh`
- [ ] Apply KDE Plasma 6 preferences on openSUSE (2x2 grid, bottom panel, KWin shortcuts, kactivitymanagerd) — `scripts/desktop/setup-desktop-preferences.sh`

### Phase 7: Final Tweaks, Testing & Orchestration

- [ ] Configure default applications (MIME types / handlers) — `scripts/apps/setup-default-apps.sh`
- [ ] Hide unwanted applications from desktop menus (`.desktop` files) — `scripts/desktop/setup-hide-apps.sh`
- [ ] Create openSUSE runner and pipeline (`runners/opensuse.sh`, integration in `runners/main.sh` and `Makefile`)
- [ ] Create Docker test containers (`setup-test-opensuse-tumbleweed`, `setup-test-opensuse-leap`)
- [ ] Add unit and integration tests for openSUSE

---

## 🔮 Future Secondary Distributions

- [ ] Vanilla Ubuntu (GNOME)
- [ ] Zorin OS
