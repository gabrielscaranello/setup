# 🪟 Guia de Instalação e Provisionamento do WSL (Arch Linux + Debian 13)

🇺🇸 **English Documentation:** [wsl.md](wsl.md)

Este guia reúne o passo a passo completo — baseado na **documentação oficial da Microsoft (WSL)** e na **ArchWiki (Official Arch Linux WSL image)** — para instalar e configurar o **WSL 3** com **Arch Linux** (distro principal), **Debian 13 Trixie** (distro de fallback), a fonte **JetBrains Mono Nerd Font** e um **disco persistente `.vhdx` `ext4` montando toda a `$HOME` automaticamente** antes de executar `./main.sh wsl` (ou `make all`).

---

## 1. Instalação e Atualização do Motor WSL (WSL 3)

Abra o **PowerShell como Administrador** no Windows 11:

```powershell
# 1. Instalar/atualizar o motor do WSL para a versão mais recente (WSL 3.x)
wsl --install --no-distribution
wsl --update

# 2. Garantir a arquitetura de máquina virtual (geração 2) como padrão
wsl --set-default-version 2

# 3. Verificar a versão instalada (deve exibir Versão do WSL: 3.x.x)
wsl --version
```

> [!NOTE]
> **Por que `wsl --version` mostra `3.x` mas `--set-default-version` usa `2`?**
> O pacote do WSL na Microsoft Store está na **versão 3 (`3.0.x`)**, mas o parâmetro `--set-default-version` define apenas a geração da arquitetura de execução (`1` = camada de tradução de syscalls legada vs. `2` = máquina virtual leve Hyper-V usada pelo WSL 3). Se for a primeira vez habilitando o WSL na máquina, reinicie o Windows quando solicitado.

---

## 2. Instalar a Fonte JetBrains Mono Nerd Font no Windows

No WSL, quem renderiza os textos e ícones na tela é o **Windows Terminal** (no sistema hospedeiro Windows). Por isso, para que os ícones do Neovim, Lazygit, Lazydocker, `eza` e Zsh funcionem, a fonte precisa estar instalada **no Windows**:

### 2.1. Instalar via `winget` no PowerShell

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont -e
```

### 2.2. Ativar no Windows Terminal

1. Abra o **Windows Terminal** e pressione `Ctrl + ,` para abrir as **Configurações**.
2. No menu lateral esquerdo, em **Perfis**, clique em **Padrões** (*Defaults*) -> **Aparência** (*Appearance*).
3. Em **Tipo de fonte** (*Font face*), selecione **`JetBrainsMono Nerd Font`** (ou `JetBrainsMono NF`) e clique em **Salvar**.

*(Alternativamente, pressione `Ctrl + Shift + ,` para abrir o `settings.json` do Windows Terminal e adicione `"font": { "face": "JetBrainsMono Nerd Font" }` dentro de `"profiles": { "defaults": { ... } }`).*

> [!TIP]
> Se você também utiliza aplicativos gráficos Linux via **WSLg**, pode instalar a fonte dentro do sistema Linux executando `./main.sh fonts`.

---

## 3. Instalação das Distribuições Oficiais (Arch Linux + Debian 13)

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

## 4. Disco `.vhdx` `ext4` Persistente com Montagem Automática (Windows 11 Home, Pro & Enterprise)

Para que toda a sua pasta de usuário (`$HOME` — incluindo repositórios, chaves SSH, dotfiles, histórico do Zsh e ferramentas instaladas) sobreviva mesmo se uma distribuição for recriada (`wsl --unregister archlinux`), crie um disco virtual `.vhdx` dedicado formatado em `ext4` usando `wsl --mount --vhd`.

### 4.1. Criar e Anexar o `.vhdx` no PowerShell (Administrador)

O comando abaixo utiliza o **`diskpart`** nativo do Windows, funcionando tanto no **Windows 11 Home** quanto no **Windows 11 Pro / Enterprise**:

```powershell
# 1. Criar a pasta para armazenar o disco virtual persistente
New-Item -ItemType Directory -Force -Path "C:\WSL"

# 2. Criar um disco VHDX dinâmico (expandable) de até 100 GB via diskpart (compatível com Windows 11 Home e Pro)
@"
create vdisk file="C:\WSL\workspace-data.vhdx" maximum=102400 type=expandable
exit
"@ | diskpart

# 3. Anexar o VHDX no WSL sem montar partições ainda (--bare)
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --bare
```

*(Nota: Em edições Windows 11 Pro/Enterprise com o módulo Hyper-V ativo, `New-VHD -Path "C:\WSL\workspace-data.vhdx" -SizeBytes 100GB -Dynamic` produz o mesmo resultado).*

### 4.2. Formatar como `ext4` (Apenas na Primeira Vez, no Arch ou Debian)

Abra o Arch Linux (`wsl -d archlinux`):

```bash
# Identifique o novo disco de 100G sem formatação (geralmente /dev/sdc ou /dev/sdd)
lsblk

# Formate como ext4 com o rótulo (LABEL) "workspace"
sudo mkfs.ext4 -L workspace /dev/sdX
```

Saia do Arch (`exit`) e monte o disco oficialmente com o nome `workspace` no PowerShell (Administrador):

```powershell
wsl --unmount "C:\WSL\workspace-data.vhdx"
wsl --mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace
```

### 4.3. Configurar Montagem Automática Persistente no Windows

Por padrão no WSL, discos anexados via `wsl --mount --vhd` são desmontados sempre que a VM do WSL é desligada (o que ocorre após 8 segundos sem terminais abertos ou após `wsl --shutdown`). Para que `/mnt/wsl/workspace` **esteja sempre montado automaticamente**:

No **PowerShell (Administrador)**, execute:

```powershell
# 1. Evitar que a VM do WSL desligue sozinha após fechar a janela do terminal (vmIdleTimeout=-1)
@"
[wsl2]
vmIdleTimeout=-1
"@ | Set-Content -Encoding UTF8 "$env:USERPROFILE\.wslconfig"

# 2. Criar uma Tarefa Agendada com privilégio máximo para montar o VHDX no login e sob demanda das distros
$action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument '--mount --vhd "C:\WSL\workspace-data.vhdx" --name workspace'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "WSL-Mount-Workspace" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

# 3. Executar a tarefa imediatamente para validar
Start-ScheduledTask -TaskName "WSL-Mount-Workspace"
```

---

## 5. Configuração de Usuário, `sudo`, `systemd` e Montagem da `$HOME` Inteira no `.vhdx`

Ao combinar a Tarefa Agendada `WSL-Mount-Workspace` com a diretiva `[boot] command` no `/etc/wsl.conf` abaixo:
1. **Mesmo que você execute `wsl --shutdown` ou `wsl --terminate`**, a distribuição acionará a tarefa do Windows no boot e aguardará `/mnt/wsl/workspace` ser montado.
2. Em seguida, fará um **`mount --bind` de `/mnt/wsl/workspace/home/<seu_usuario>` diretamente sobre `/home/<seu_usuario>`** antes de abrir o seu shell — sem necessidade de criar links simbólicos manuais.

### 5.1. No Arch Linux (`wsl -d archlinux`)

A imagem oficial `archlinux` do WSL inicia como `root` no primeiro boot. Execute dentro do Arch Linux:

```bash
# 1. Inicializar chaveiro do pacman e instalar sudo, git, zsh e util-linux
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm sudo git zsh util-linux

# 2. Definir o nome do seu usuário e criá-lo com UID 1000 (mesmo do Debian) e Zsh como shell padrão
WSL_USER="<seu_usuario>"
useradd -m -u 1000 -G wheel -s /usr/bin/zsh "$WSL_USER"
passwd "$WSL_USER"

# 3. Habilitar sudo para o grupo wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# 4. Configurar /etc/wsl.conf (systemd nativo + usuário padrão + auto-mount do VHDX e bind-mount da $HOME inteira)
cat << EOF > /etc/wsl.conf
[boot]
systemd=true
command="/bin/sh -c 'if ! mountpoint -q /mnt/wsl/workspace; then /mnt/c/Windows/System32/schtasks.exe /run /tn WSL-Mount-Workspace >/dev/null 2>&1 || true; for i in 1 2 3 4 5; do mountpoint -q /mnt/wsl/workspace && break; sleep 1; done; fi; if mountpoint -q /mnt/wsl/workspace && ! mountpoint -q /home/$WSL_USER; then mkdir -p /mnt/wsl/workspace/home/$WSL_USER && chown 1000:1000 /mnt/wsl/workspace/home/$WSL_USER && mount --bind /mnt/wsl/workspace/home/$WSL_USER /home/$WSL_USER; fi'"

[user]
default=$WSL_USER
EOF
```

Saia do Arch (`exit`) e reinicie a instância no PowerShell:

```powershell
wsl --terminate archlinux
```

Ao abrir o Arch novamente (`wsl -d archlinux`), sua `$HOME` (`/home/<seu_usuario>`) já estará montada diretamente no disco persistente `.vhdx` (confirme com `df -h ~`).

### 5.2. No Debian 13 (`wsl -d Debian`)

O instalador oficial do Debian no WSL solicita a criação do seu usuário padrão (UID `1000`) e senha no primeiro boot — **informe o mesmo nome de usuário criado no Arch Linux**. Em seguida, configure o `git`, `zsh` e o `/etc/wsl.conf` apontando para a mesma `$HOME` no `.vhdx`:

```bash
# 1. Instalar git, curl, ca-certificates, zsh e mount
sudo apt update && sudo apt install -y git curl ca-certificates zsh mount

# 2. Definir o Zsh como shell padrão para que os exports de PATH utilizem ~/.zshrc
sudo chsh -s /usr/bin/zsh "$USER"

# 3. Configurar /etc/wsl.conf (systemd nativo + usuário padrão + auto-mount do VHDX e bind-mount da $HOME inteira)
sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true
command="/bin/sh -c 'if ! mountpoint -q /mnt/wsl/workspace; then /mnt/c/Windows/System32/schtasks.exe /run /tn WSL-Mount-Workspace >/dev/null 2>&1 || true; for i in 1 2 3 4 5; do mountpoint -q /mnt/wsl/workspace && break; sleep 1; done; fi; if mountpoint -q /mnt/wsl/workspace && ! mountpoint -q /home/$USER; then mkdir -p /mnt/wsl/workspace/home/$USER && chown 1000:1000 /mnt/wsl/workspace/home/$USER && mount --bind /mnt/wsl/workspace/home/$USER /home/$USER; fi'"

[user]
default=$USER
EOF
```

Saia do Debian (`exit`) e reinicie a instância no PowerShell:

```powershell
wsl --terminate Debian
```

---

## 6. Executando o Pipeline do WSL (`runners/wsl.sh`)

Com a `$HOME` montada no `.vhdx`, clone este repositório e execute o setup:

```bash
mkdir -p ~/Code/Github
cd ~/Code/Github
git clone https://github.com/gabrielscaranello/setup.git
cd setup

# Executa o pipeline completo de desenvolvimento para WSL (ou `make all`, que autodetecta o WSL)
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
