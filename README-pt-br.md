# Desktop Setup

Descrição
--------

Este repositório contém scripts de configuração para ambientes desktop Linux multiplataforma. O objetivo é fornecer um conjunto único de scripts que funcionem em Ubuntu/Debian, Fedora/RHEL, openSUSE e Arch Linux, instalando e configurando utilitários como o Neovim e ajustes de terminal.

Objetivo do projeto
-------------------

- Automatizar a configuração de um ambiente de desenvolvimento desktop em várias distribuições Linux.
- Manter os scripts genéricos e idempotentes, com abstração de gerenciador de pacotes.
- Facilitar testes, reutilização e manutenção por meio de scripts modulares em scripts/*.sh.

Como usar (rápido)
-------------------

| action          | description                                 |
| --------------- | ------------------------------------------- |
| `make help`     | Mostrar ajuda dos alvos:                    |
| `make all`      | Executar todo o setup (executa `./main.sh`) |
| `make neovim`   | Executar apenas o setup do Neovim           |
| `make nvm`      | Executar apenas o setup do nvm/Node         |
| `make terminal` | Executar apenas o setup do terminal         |
| `make clean`    | Limpar arquivos temporários:                |

Makefile - Alvos e descrição
---------------------------

- help
  - Exibe a lista de alvos disponíveis e uma breve descrição.

- all
  - Executa o script principal `./main.sh`, que orquestra os demais scripts em sequência.

- neovim
  - Chama `scripts/setup-neovim.sh` para instalar o Neovim. O script garante que o `nvm` esteja instalado (é necessário pelo toolchain do Neovim); quando o gerenciador de pacotes é `dnf` ou `pacman`, usa o pacote da distro; caso contrário compila a partir da fonte.

- nvm
  - Chama `scripts/setup-nvm.sh` para instalar o nvm, Node e habilitar o corepack; no Arch é usado o pacote `nvm` do repositório.

- terminal
  - Chama `scripts/setup-terminal.sh`. Atualmente é um stub; destinado a instalar e configurar ferramentas/temas/plug-ins do terminal.

- clean
  - Remove artefatos temporários (ex.: `/tmp/neovim`) para liberar espaço e garantir builds limpos.

Estrutura de diretórios
-----------------------

- main.sh - Orquestrador que executa os scripts em sequência
- Makefile - Runner com alvos convenientes (make all, make neovim, ...)
- scripts/_utils.sh - Abstração do gerenciador de pacotes e utilitários genéricos
- scripts/setup-neovim.sh- Script para compilar/instalar Neovim
- scripts/setup-terminal.sh - Script para ajustes de terminal (a completar)

Requisitos / Pré-requisitos
--------------------------

- Acesso sudo para instalar pacotes
- Git para clonar repositórios (Neovim)
- Shell Bash (scripts usam recursos do bash)

Contribuindo
-----------

- Novos recursos devem ser implementados como `scripts/setup-<nome>.sh` e adicionados em `main.sh` e ao Makefile se necessário.
- Manter `_utils.sh` genérico — não incluir lógica específica de pacote nele.
- Validar scripts com `shellcheck -x scripts/*.sh` e testar alvos do Makefile.
