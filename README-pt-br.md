# 🚀 Desktop Setup

Bem-vindo! Este repositório automatiza a configuração de um ambiente de desenvolvimento desktop Linux, funcionando em várias distribuições (Debian, Fedora, Arch Linux).

> [!WARNING]
> Este projeto está em fases iniciais de desenvolvimento e estudo. Ele **não está completo** e muita coisa **pode mudar**. Use por sua conta e risco.

✨ O que é
--------

- Scripts idempotentes em scripts/*.sh para instalar e configurar ferramentas (Neovim, Node.js via NVM, etc.).

🎯 Objetivos
-----------

- Automatizar a provisão de um ambiente dev desktop.
- Manter scripts genéricos, reutilizáveis e distribuídos por gerenciador de pacotes.
- Facilitar testes e manutenção com scripts modulares.

⚡️ Começando (rápido)
---------------------

Execute os alvos do Makefile:

```sh
make help              # Ver alvos disponíveis
make all               # Executa todo o setup (./main.sh)
make neovim            # Só Neovim
make nvm               # Só NVM/Node
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
- scripts/setup-neovim.sh — Instala/compila Neovim
- scripts/setup-nvm.sh — Instala NVM, Node.js e pacotes globais

🛠 Requisitos
------------

- sudo
- git
- bash

## 📖 Mais informações

Consulte o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para o template de scripts e o fluxo de contribuição.

Made with ❤️ — happy hacking!
