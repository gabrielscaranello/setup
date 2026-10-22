# 🪟 Guia de Instalação e Provisionamento do WSL2

🇺🇸 **English Documentation:** [wsl.md](wsl.md)

Este guia reúne o passo a passo completo — baseado na **documentação oficial da Microsoft (WSL 2)** e na **ArchWiki (Official Arch Linux WSL image)** — para instalar e configurar o WSL2 com **Arch Linux** (distro principal), **Debian 13 Trixie** (distro de fallback) e um **disco persistente `.vhdx` `ext4` compartilhado** antes de executar `./main.sh wsl` (ou `make all`).

---

## 1. Instalação e Atualização do Motor WSL2 (Windows)

Abra o **PowerShell como Administrador** no Windows 11 (ou Windows 10 22H2+):

```powershell
# 1. Instalar/atualizar o motor do WSL2 (versão da Microsoft Store com suporte a systemd, WSLg e --vhd)
wsl --install --no-distribution
wsl --update

# 2. Garantir que o WSL 2 seja a versão padrão para todas as distribuições
wsl --set-default-version 2
```

> [!NOTE]
> Se for a primeira vez habilitando o WSL na máquina, reinicie o Windows quando solicitado antes de prosseguir.

---

## 2. Instalação das Distribuições Oficiais (Arch Linux + Debian 13)

Tanto o **Arch Linux** (`archlinux`) quanto o **Debian** (`Debian`) fazem parte do manifesto oficial do WSL da Microsoft (`wsl --list --online`):

```powershell
# Verificar as distribuições disponíveis oficialmente:
wsl --list --online

# 1. Instalar o Arch Linux oficial (Distro Principal)
wsl --install archlinux

# 2. Instalar o Debian 13 Trixie oficial (Distro de Fallback)
wsl --install -d Debian

# Definir o Arch Linux como distribuição padrão ao digitar `wsl`
wsl --set-default archlinux
```

---

## 3. Configuração Inicial de Usuário, `sudo` e `systemd`

Os scripts de configuração deste repositório (`setup-docker.sh`, `setup-cli.sh`, `setup-neovim.sh`, etc.) exigem:

- Um usuário regular (não-root) com privilégios `sudo` (requisito de `scripts/_utils.sh` e serviços).
- `systemd=true` ativo em `/etc/wsl.conf` (requisito para `systemctl enable/start docker.service` funcionar nativamente em `scripts/toolchain/setup-docker.sh`).
- `git` e `sudo` instalados (pré-requisitos do `README-pt-br.md`).

### 3.1. No Arch Linux (`wsl -d archlinux`)

A imagem oficial `archlinux` do WSL inicia como `root` no primeiro boot. Execute dentro do Arch Linux:

```bash
# 1. Inicializar chaveiro do pacman e instalar sudo, git e zsh
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm sudo git zsh

# 2. Criar seu usuário regular com UID 1000 (mesmo do Debian) e Zsh como shell padrão
useradd -m -u 1000 -G wheel -s /usr/bin/zsh gabriel
passwd gabriel

# 3. Habilitar sudo para o grupo wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# 4. Configurar /etc/wsl.conf (usuário padrão + systemd nativo)
cat << 'EOF' > /etc/wsl.conf
[boot]
systemd=true

[user]
default=gabriel
EOF
```

Saia do Arch (`exit`) e reinicie a instância pelo PowerShell:

```powershell
wsl --terminate archlinux
```

### 3.2. No Debian 13 (`wsl -d Debian`)

O instalador oficial do Debian no WSL solicita a criação do seu usuário padrão (UID `1000`) e senha no primeiro boot. Em seguida, instale `git`, `curl` e `zsh`, e garanta o `systemd=true` no `/etc/wsl.conf`:

```bash
# 1. Instalar git, curl, ca-certificates e zsh
sudo apt update && sudo apt install -y git curl ca-certificates zsh

# 2. (Opcional) Definir o Zsh como shell padrão para que os exports de PATH utilizem ~/.zshrc
sudo chsh -s /usr/bin/zsh "$USER"

# 3. Habilitar systemd e definir o usuário padrão em /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true

[user]
default=$USER
EOF
```

Saia do Debian (`exit`) e reinicie a instância pelo PowerShell:

```powershell
wsl --terminate Debian
```

---

## 4. Disco `.vhdx` `ext4` Persistente (Compartilhado entre Distros)

Para que seus repositórios, chaves SSH e área de trabalho sobrevivam mesmo se uma distribuição for recriada (`wsl --unregister archlinux`), crie um disco virtual `.vhdx` dedicado formatado em `ext4` usando `wsl --mount --vhd`:

### 4.1. Criar e Anexar o `.vhdx` no PowerShell (Administrador)

```powershell
# Criar a pasta para armazenar o disco virtual persistente
New-Item -ItemType Directory -Force -Path "C:\WSL"

# Criar um disco VHDX dinâmico de até 100 GB (ocupa no SSD apenas o espaço efetivamente utilizado)
New-VHD -Path "C:\WSL\workspace-data.vhdx" -SizeBytes 100GB -Dynamic

# Anexar o VHDX no WSL2 sem montar partições ainda (--bare)
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --bare
```

### 4.2. Formatar como `ext4` (Apenas na Primeira Vez, no Arch ou Debian)

Abra o Arch Linux (`wsl -d archlinux`):

```bash
# Identifique o novo disco de 100G sem formatação (geralmente /dev/sdc ou /dev/sdd)
lsblk

# Formate como ext4 com o rótulo (LABEL) "workspace"
sudo mkfs.ext4 -L workspace /dev/sdX
```

### 4.3. Montar e Compartilhar entre Arch Linux e Debian 13

No PowerShell (Administrador):

```powershell
# Desmontar o modo --bare e montar oficialmente com o nome "workspace"
wsl --unmount "C:\WSL\workspace-data.vhdx"
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace
```

Pela documentação oficial da Microsoft, qualquer disco montado via `wsl --mount --name workspace` fica automaticamente disponível em **`/mnt/wsl/workspace`** para **todas as distribuições WSL2 em execução simultaneamente** (tanto no Arch Linux quanto no Debian 13).

Dentro do Arch Linux (`wsl -d archlinux`), ajuste a permissão para o UID `1000` e crie os diretórios persistentes:

```bash
sudo chown -R 1000:1000 /mnt/wsl/workspace
mkdir -p /mnt/wsl/workspace/{Code,.ssh}
chmod 700 /mnt/wsl/workspace/.ssh

# Criar symlinks no $HOME (repita estes dois comandos ln -sfn também dentro do Debian):
ln -sfn /mnt/wsl/workspace/Code ~/Code
ln -sfn /mnt/wsl/workspace/.ssh ~/.ssh
```

---

## 5. Executando o Pipeline do WSL (`runners/wsl.sh`)

Clone este repositório dentro do seu workspace persistente e execute o setup:

```bash
mkdir -p ~/Code/Github
cd ~/Code/Github
git clone https://github.com/gabrielscaranello/setup.git
cd setup

# Executa o pipeline completo de desenvolvimento para WSL (ou `make all`, que autodetecta o WSL2)
./main.sh wsl
```

### O que o `./main.sh wsl` (ou `make all` no WSL) provisiona automaticamente:

1. **`system/setup-update.sh`**: Atualiza os metadados de repositórios e todos os pacotes instalados (`pacman -Syu` no Arch ou `apt update && apt upgrade` no Debian 13).
2. **`terminal/setup-cli.sh`**: Instala `bat` (com symlink `batcat -> ~/.local/bin/bat` no Debian), `btop`, `eza`, `gdu`, `zsh`, `zsh-completions`, `man-db`, `openssh`, `dialog`, `keychain` e `wl-clipboard` (integrado ao clipboard do Windows via Wayland/WSLg).
3. **`toolchain/setup-docker.sh`**: Instala Docker Engine, `docker-compose`, `docker-buildx`, habilita o `docker.service` via `systemd` e adiciona seu usuário ao grupo `docker`.
4. **`toolchain/setup-gitflow.sh`**: Instala o Gitflow CJS.
5. **`toolchain/setup-gh.sh`**: Instala o pacote nativo do GitHub CLI (`gh`) em ambientes WSL.
6. **`toolchain/setup-python.sh`**: Instala `python3`, `pip` e `venv`.
7. **`toolchain/setup-go.sh`**: Instala Golang e `dockerfmt`, configurando `GOPATH` e `PATH` no perfil do shell.
8. **`toolchain/setup-nvm.sh`**: Instala NVM, Node.js 24, habilita Corepack (`yarn`) e instala pacotes globais (`@github/copilot`, `@styled/typescript-styled-plugin`).
9. **`terminal/setup-lazygit.sh` & `terminal/setup-lazydocker.sh`**: Instala Lazygit e Lazydocker.
10. **`toolchain/setup-neovim.sh`**: Provisiona automaticamente Rust/Cargo + `tree-sitter-cli`, dependências de runtime do Neovim (`ripgrep`, `fd`, `luarocks`, `jq`, `sqlite`, `imagemagick`, `tidy`, `protobuf`) e o Neovim (pacote `pacman` no Arch ou compilado da branch `stable` `.deb` no Debian 13).
