.PHONY: help all neovim nvm terminal clean

SHELL := /bin/bash
SCRIPTS_DIR := scripts

help:
	@echo "======================================="
	@echo "   Desktop Setup - Available Targets"
	@echo "======================================="
	@echo ""
	@echo "  make all              - Run complete setup (all scripts)"
	@echo "  make help             - Show this help message"
	@echo "  make neovim           - Install Neovim (from source or distro repo as appropriate)"
	@echo "  make nvm              - Install nvm and Node (used by Neovim toolchain)"
	@echo "  make terminal         - Setup terminal"
	@echo "  make clean            - Clean temporary build files"
	@echo ""

all:
	@./main.sh

neovim:
	@./$(SCRIPTS_DIR)/setup-neovim.sh

nvm:
	@./$(SCRIPTS_DIR)/setup-nvm.sh

terminal:
	@./$(SCRIPTS_DIR)/setup-terminal.sh

clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/neovim
	@echo "✓ Clean completed"
