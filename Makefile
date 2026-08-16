.PHONY: help all neovim terminal clean

SHELL := /bin/bash
SCRIPTS_DIR := scripts

help:
	@echo "================================"
	@echo "   Desktop Setup - Available Targets"
	@echo "================================"
	@echo ""
	@echo "  make all              - Run complete setup (all scripts)"
	@echo "  make neovim           - Install Neovim from source"
	@echo "  make terminal         - Setup terminal"
	@echo "  make help             - Show this help message"
	@echo "  make clean            - Clean temporary build files"
	@echo ""

all:
	@./main.sh

neovim:
	@./$(SCRIPTS_DIR)/setup-neovim.sh

terminal:
	@./$(SCRIPTS_DIR)/setup-terminal.sh

clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/neovim
	@echo "✓ Clean completed"
