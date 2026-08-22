# Makefile targets ordering rule:
# - New script targets MUST be added here and in [README.md](README.md) / [README-pt-br.md](README-pt-br.md)
# - Order runtime targets alphabetically, but ensure 'help' and 'all' are first and 'clean' is last.
.PHONY: help all neovim nvm test test-coverage clean
.DEFAULT_GOAL := help

SHELL := /bin/bash
SCRIPTS_DIR := scripts
TESTS_DIR := tests

help:
	@echo "======================================="
	@echo "   Desktop Setup - Available Targets"
	@echo "======================================="
	@echo ""
	@echo "  make help                  - Show this help message"
	@echo "  make all                   - Run complete setup (all scripts)"
	@echo "  make neovim                - Install Neovim (from source or distro repo)"
	@echo "  make nvm                   - Install nvm, Node and global packages"
	@echo "  make test                  - Run all integration tests (all distros)"
	@echo "  make test-coverage         - Run tests and generate code coverage reports"
	@echo "  make clean                 - Clean temporary build files"
	@echo ""

all:
	@./main.sh

neovim:
	@./$(SCRIPTS_DIR)/setup-neovim.sh

nvm:
	@./$(SCRIPTS_DIR)/setup-nvm.sh

# ── Integration tests ────────────────────────────────────────────────────────

test:
	@./$(TESTS_DIR)/run-tests.sh

test-coverage:
	@./$(TESTS_DIR)/run-tests.sh --coverage

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/neovim coverage
	@echo "✓ Clean completed"
