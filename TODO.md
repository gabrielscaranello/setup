# 📋 Project Roadmap & Execution Plan (TODO)

Este documento acompanha os marcos de desenvolvimento, tarefas em andamento e funcionalidades planejadas para o projeto Desktop Setup.

---

## 🎯 Milestone 2.0: Suporte ao LMDE (Linux Mint Debian Edition) & Cinnamon (Em Andamento)

O objetivo principal deste marco é estender todo o ferramental idempotente do projeto para fornecer suporte nativo de primeira classe ao **LMDE 7** (baseado em **Debian 13 Trixie**) com o ambiente de desktop **Cinnamon**.

---

### 🟢 Fase 1: Fundação & Identificação do LMDE e Cinnamon

Adaptação do núcleo de abstração para reconhecer e tratar o LMDE e o ambiente Cinnamon sem quebrar a compatibilidade com Debian, Fedora e Arch Linux.

- [ ] Identificação de distribuição: atualizar `get_distro_id`, `is_distro` e `require_supported_distro` em `scripts/utils/_system.sh` para reconhecer `lmde` (via `ID=linuxmint` e `ID_LIKE=debian` ou `NAME="LMDE"`)
- [ ] Detecção de Desktop Environment: atualizar `get_desktop_environment` e `prompt_desktop_environment` em `scripts/utils/_desktop.sh` para reconhecer `cinnamon` (`XDG_CURRENT_DESKTOP=X-Cinnamon` / `cinnamon`)
- [ ] Mapeamento de pacotes: garantir resolução em `scripts/utils/_packages.sh` tratando `lmde` como consumidor da base Debian com extensões próprias, e atualizar `scripts/packages.conf` se houver divergências
- [ ] Testes unitários do núcleo: atualizar `tests/unit/utils-system.bats` e `tests/unit/utils-desktop.bats` cobrindo cenários do LMDE e Cinnamon

---

### 🐳 Fase 2: Infraestrutura de Testes & Container LMDE

Provisionamento do ambiente Docker para validação segura de scripts e execução de testes de integração sem executar comandos na máquina host.

- [ ] Criar Dockerfile de testes para LMDE: `tests/docker/lmde.Dockerfile` baseado na imagem oficial de Debian Trixie com repositórios Mint ou imagem base LMDE
- [ ] Integrar LMDE ao harness de testes: atualizar `tests/run-tests.sh` e `Makefile` (`test-integration-lmde`)
- [ ] Validar execução de suite de testes unitários e de integração dentro do novo container LMDE

---

### ⚙️ Fase 3: Sistema, Repositórios, Codecs & Hardware no LMDE

Configuração dos aspectos de baixo nível do sistema operacional específicos para o ecossistema Mint/Debian.

- [ ] Repositórios e fontes de pacotes: criar `scripts/system/lmde/_repositories.sh` (configuração idempotente de repositórios oficiais Mint, Debian e Backports)
- [ ] Codecs e multimídia: adaptar `scripts/system/setup-codecs.sh` para utilizar `mint-meta-codecs` ou pacotes específicos quando executado no LMDE
- [ ] Drivers gráficos e aceleração: validar/adaptar `scripts/system/setup-graphics.sh`, `setup-nvidia.sh` e `setup-amd.sh` no contexto do LMDE
- [ ] Firewall e segurança: adaptar `scripts/security/setup-firewall.sh` para suporte a `gufw` e regras de firewall adequadas ao desktop Cinnamon
- [ ] Gerenciamento de snapshots (Timeshift): adaptar `scripts/system/setup-timeshift.sh` para o LMDE, aplicando os filtros e agendamentos refinados (retenção horária/diária/semanal, exclusão de steam/node_modules/cache/docker e inclusão de `.**`, `Code/`, documentos)

---

### 🧹 Fase 4: Limpeza, Debloat e Pacotes Base

Padronização dos pacotes essenciais e remoção de bloatware do ecossistema Mint.

- [ ] Debloat no LMDE: atualizar `scripts/system/setup-debloat.sh` para remover os bloatwares típicos identificados no LMDE (`celluloid`, `gnome-terminal`, `hypnotix*`, `libreoffice*`, `mintchat`, `rhythmbox`, `simple-scan`, `sticky`, `thingy`, `thunderbird*`, `transmission*`, `xterm*`)
- [ ] Atualização do sistema: adaptar `scripts/system/setup-update.sh` considerando `mintupdate-cli` ou `apt`
- [ ] Pacotes essenciais do sistema: estender `scripts/system/setup-packages.sh` com utilitários essenciais do LMDE (`nemo-fileroller`, `xclip`, `zram-tools`, `libu2f-udev`, `numlockx`, etc.)

---

### 💻 Fase 5: Ferramentas de Desenvolvimento e Aplicativos GUI

Garantir funcionamento pleno da suite completa de desenvolvimento e produtividade no LMDE.

- [ ] Toolchain de desenvolvimento: validar e garantir execução dos scripts em `scripts/toolchain/` no LMDE (`setup-docker.sh`, `setup-neovim.sh`, `setup-nvm.sh`, `setup-go.sh`, `setup-gitflow.sh`)
- [ ] Terminal e fontes: validar `scripts/terminal/setup-fonts.sh`, `setup-kitty.sh`, `setup-lazygit.sh` e `setup-lazydocker.sh` no LMDE
- [ ] Navegadores web: adaptar `scripts/apps/setup-browsers.sh` para o LMDE (Mint já empacota Firefox vanilla nativo `.deb` via repositório próprio)
- [ ] Aplicativos GUI: validar funcionamento dos scripts de apps (`setup-vscodium.sh`, `setup-onlyoffice.sh`, `setup-obsidian.sh`, `setup-dbeaver.sh`, `setup-steam.sh`, `setup-discord.sh`, etc.) via apt/flatpak
- [ ] Captura de tela: adaptar `scripts/apps/setup-screenshot-tool.sh` para Cinnamon (`flameshot` com atalhos do Cinnamon)
- [ ] Associações de aplicativos padrão (MIME): adaptar `scripts/apps/setup-default-apps.sh` com suporte a Cinnamon/LMDE (VLC para mídia, Xviewer para imagens, OnlyOffice para documentos, Xed para texto e Nemo para diretórios)

---

### 🌿 Fase 6: Customização do Cinnamon Desktop Environment

Personalização completa da interface gráfica Cinnamon para manter a mesma consistência visual e ergonômica de GNOME e KDE Plasma.

- [ ] Tema de cursores e ícones: adaptar `scripts/desktop/setup-cursor-theme.sh` (`Bibata-Modern-Ice`, tam 20) e `setup-icon-theme.sh` (`Papirus-Dark` + `cat-mocha-lavender`) para Cinnamon via `gsettings` (`org.cinnamon.desktop.interface`)
- [ ] Tema GTK: adaptar `scripts/desktop/setup-gtk-theme.sh` para aplicar `Colloid-Dark-Catppuccin` no Cinnamon (`org.cinnamon.desktop.interface gtk-theme`, `org.cinnamon.desktop.wm.preferences theme` e `org.cinnamon.theme name`)
- [ ] Orquestrador de aparência: atualizar `scripts/desktop/setup-look.sh` para coordenar cursor, ícones e GTK no Cinnamon
- [ ] Applets e Extensões (Cinnamon Spices): implementar download e instalação de spices via API do Linux Mint (`color-picker@fmete`, `transparent-panels-reloaded@marcelovbcfilho`) em `scripts/desktop/setup-cinnamon-applets.sh`
- [ ] Configuração do Painel e Applets: implementar `scripts/desktop/setup-cinnamon-applets-config.sh` (layout do painel com menu, agrupador de janelas à esquerda e bandeja, relógio, color-picker à direita)
- [ ] Preferências do Cinnamon Desktop: implementar `scripts/desktop/setup-cinnamon-preferences.sh` (layout minimalista de botões `:close`, centralização de novas janelas no Muffin, Night Light, hotcorners expo/scale e Nemo sem ícones no desktop)
- [ ] Ocultar aplicativos desnecessários no menu: adaptar `scripts/desktop/setup-hide-apps.sh` para garantir compatibilidade com o menu do Cinnamon

---

### 🚀 Fase 7: Orquestração, Runner do LMDE & Documentação

Criação dos pontos de entrada, documentação e especificações OpenSpec.

- [ ] Criar runner dedicado para LMDE: `runners/lmde.sh` seguindo o padrão modular (`_run_stage`, pipeline de execução sequencial)
- [ ] Atualizar despachante central: registrar suporte a `lmde` em `runners/main.sh` e `main.sh` (incluindo help e autodirecionamento por distro)
- [ ] Especificações OpenSpec: criar/atualizar especificações em `openspec/specs/` documentando os novos requisitos e cenários GIVEN/WHEN/THEN para LMDE e Cinnamon
- [ ] Documentação: atualizar `README.md` e `README-pt-br.md` incluindo o LMDE na lista de distribuições suportadas e instruções de uso

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

## 🔮 Futuras Distribuições Secundárias (Post-LMDE)

- [ ] Linux Mint (base Ubuntu)
- [ ] Ubuntu puro (GNOME)
- [ ] openSUSE Tumbleweed / Leap
- [ ] Zorin OS
