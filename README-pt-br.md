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

Execute o setup completo ou consulte os módulos disponíveis:

```sh
make help              # Ver todos os comandos e módulos disponíveis (./main.sh help)
make all               # Executa todo o setup (./main.sh)
make <modulo>          # Executa um módulo específico (ex: make neovim, make docker, make firewall)
make test              # Executa todos os testes (ex: DISTRO=debian FILTER=nvm)
make test-unit         # Executa apenas testes unitários rápidos
make test-integration  # Executa apenas testes de integração em containers
make test-coverage     # Executa testes e gera relatórios de cobertura (kcov)
make clean             # Limpa artefatos temporários
```

📂 Arquitetura & Estrutura de Diretórios
---------------------------------------

- `main.sh` — Ponto de entrada central que redireciona para `runners/main.sh`
- `runners/` — Runners de pipelines específicos por distribuição (`arch.sh`, `debian.sh`, `fedora.sh`, `main.sh`)
- `Makefile` — Runner e alias de conveniência para `./main.sh` e testes
- `scripts/` — Scripts modulares organizados por domínios (`system/`, `security/`, `toolchain/`, `terminal/`, `apps/`)
- `scripts/_utils.sh` — Abstrações de sistema e gerenciadores de pacotes
- `scripts/packages.conf` — Mapeamento declarativo de pacotes entre distros
- `tests/` — Testes unitários (Bats) e de integração multi-distro (Docker)

🛠 Requisitos
------------

- sudo
- git
- bash

## 📖 Mais informações

- Consulte o arquivo [TODO.md](TODO.md) para o roadmap do projeto, funcionalidades implementadas e tarefas planejadas.
- Consulte o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para o template de scripts e o fluxo de contribuição.

Made with ❤️ — happy hacking!
