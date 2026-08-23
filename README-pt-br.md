# 🚀 Desktop Setup

Bem-vindo! Este repositório automatiza a configuração de um ambiente de desenvolvimento desktop Linux, funcionando em várias distribuições (Debian, Fedora, Arch Linux).

> [!WARNING]
> Este projeto está em fases iniciais de desenvolvimento e estudo. Ele **não está completo** e muita coisa **pode mudar**. Use por sua conta e risco.

✨ O que é
--------

- Uma coleção de scripts modulares e idempotentes (`scripts/*.sh`) para instalar e configurar ferramentas de desenvolvimento, runtimes, fontes e ambientes gráficos em várias distribuições Linux.

💡 Motivação e Contexto
-----------------------

Este projeto nasceu para unificar e centralizar diversos repositórios isolados de configuração em uma única base de código, facilitando meu fluxo diário de [distro-hopping](https://en.wiktionary.org/wiki/distro-hopping) (o hábito comum de testar e alternar frequentemente entre diferentes distribuições Linux):

- 🌀 [gabrielscaranello/debian](https://github.com/gabrielscaranello/debian)
- 🌿 [gabrielscaranello/mint-setup](https://github.com/gabrielscaranello/mint-setup)
- 🎩 [gabrielscaranello/fedora-setup](https://github.com/gabrielscaranello/fedora-setup)
- 🐧 [gabrielscaranello/arch-setup](https://github.com/gabrielscaranello/arch-setup)
- 🔷 [gabrielscaranello/zorin-setup](https://github.com/gabrielscaranello/zorin-setup)
- 🦎 [gabrielscaranello/opensuse](https://github.com/gabrielscaranello/opensuse)

---

> [!NOTE]
> **Setup Pessoal vs. Utilitário Geral**: Este repositório foi construído sob medida para atender ao meu fluxo de trabalho, preferências e opiniões pessoais. Ele é compartilhado abertamente com a comunidade como referência e inspiração para scripts multi-distro modulares.
>
> Caso procure um utilitário pós-instalação completo e de propósito geral voltado para a comunidade em geral, confira o [Linux Toys](https://github.com/psygreg/linuxtoys).
>
> Minhas configurações de usuário e dotfiles são mantidas separadamente em [gabrielscaranello/dotfiles](https://github.com/gabrielscaranello/dotfiles) (com uma possível integração futura planejada por aqui).

🎯 Objetivos
-----------

- Centralizar e automatizar a provisão de um ambiente dev desktop.
- Manter scripts genéricos, reutilizáveis e distribuídos por gerenciador de pacotes.
- Facilitar testes e manutenção com scripts modulares.

⚡️ Começando (rápido)
---------------------

Execute os alvos do Makefile:

```sh
make help              # Ver alvos disponíveis
make all               # Executa todo o setup (./main.sh)
make browsers          # Só Navegadores (Chromium, Firefox)
make docker            # Só Docker
make flatpak           # Só Flatpak e Flathub
make fonts             # Só JetBrains Mono Nerd Font
make gitflow           # Só Gitflow CJS
make go                # Só Golang
make kitty             # Só Kitty terminal emulator
make lazydocker        # Só Lazydocker
make lazygit           # Só Lazygit
make neovim            # Só Neovim
make nvm               # Só NVM/Node
make rust              # Só Rust/Cargo
make test              # Executa todos os testes (ex: DISTRO=debian FILTER=nvm)
make test-coverage     # Executa testes e gera relatórios de cobertura (kcov)
make test-integration  # Executa apenas testes de integração em containers
make test-unit         # Executa apenas testes unitários rápidos
make clean             # Limpa artefatos temporários
```

📂 Estrutura
-----------

- main.sh — Orquestrador
- Makefile — Runner com alvos úteis
- scripts/_utils.sh — Abstração do gerenciador de pacotes
- scripts/setup-browsers.sh — Instala Navegadores (Chromium, Firefox)
- scripts/setup-docker.sh — Instala Docker e plugins
- scripts/setup-flatpak.sh — Configura Flatpak e repositório Flathub
- scripts/setup-fonts.sh — Instala JetBrains Mono Nerd Font
- scripts/setup-gitflow.sh — Instala Gitflow CJS
- scripts/setup-go.sh — Instala Golang
- scripts/setup-kitty.sh — Instala Kitty terminal emulator
- scripts/setup-lazydocker.sh — Instala Lazydocker
- scripts/setup-lazygit.sh — Instala Lazygit
- scripts/setup-neovim.sh — Instala/compila Neovim
- scripts/setup-nvm.sh — Instala NVM, Node.js e pacotes globais
- scripts/setup-rust.sh — Instala Rust, Cargo e ferramentas (tree-sitter-cli)

🛠 Requisitos
------------

- sudo
- git
- bash

## 📖 Mais informações

- Consulte o arquivo [TODO.md](TODO.md) para o roadmap do projeto, funcionalidades implementadas e tarefas planejadas.
- Consulte o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para o template de scripts e o fluxo de contribuição.

Made with ❤️ — happy hacking!
