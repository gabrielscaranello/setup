# Makefile targets ordering rule:
# - New script targets MUST be added here and in [README.md](README.md) / [README-pt-br.md](README-pt-br.md)
# - Order runtime targets alphabetically, but ensure 'help' and 'all' are first and 'clean' is last.
.PHONY: help all neovim nvm rust test test-coverage test-integration test-unit clean
.DEFAULT_GOAL := help

SHELL := /bin/bash
SCRIPTS_DIR := scripts
TESTS_DIR := tests

DISTRO ?=
FILTER ?=

help:
	@echo "======================================="
	@echo "   Desktop Setup - Available Targets"
	@echo "======================================="
	@echo ""
	@echo "  make help                  - Show this help message"
	@echo "  make all                   - Run complete setup (all scripts)"
	@echo "  make neovim                - Install Neovim (from source or distro repo)"
	@echo "  make nvm                   - Install nvm, Node and global packages"
	@echo "  make rust                  - Install Rust, Cargo and tools (tree-sitter-cli)"
	@echo "  make test                  - Run unit and integration tests (supports DISTRO=, FILTER=)"
	@echo "  make test-coverage         - Run tests and generate code coverage reports"
	@echo "  make test-integration      - Run container integration tests only"
	@echo "  make test-unit             - Run fast unit tests only (supports FILTER=)"
	@echo "  make clean                 - Clean temporary build files"
	@echo ""

all:
	@./main.sh

neovim:
	@./$(SCRIPTS_DIR)/setup-neovim.sh

nvm:
	@./$(SCRIPTS_DIR)/setup-nvm.sh

rust:
	@./$(SCRIPTS_DIR)/setup-rust.sh

# ── Tests ────────────────────────────────────────────────────────────────────

test:
	@./$(TESTS_DIR)/run-tests.sh $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-coverage:
	@./$(TESTS_DIR)/run-tests.sh --coverage $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-integration:
	@./$(TESTS_DIR)/run-tests.sh --integration $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-unit:
	@./$(TESTS_DIR)/run-tests.sh --unit $(if $(FILTER),--filter=$(FILTER))

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/neovim coverage
	@echo "✓ Clean completed"
