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

## 🔮 Futuras Distribuições Secundárias

- [ ] Ubuntu puro (GNOME)
- [ ] openSUSE Tumbleweed / Leap
- [ ] Zorin OS
