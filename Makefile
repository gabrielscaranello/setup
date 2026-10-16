# Makefile — Light wrapper around ./main.sh and ./tests/run-tests.sh
.PHONY: help all test test-coverage test-integration test-unit clean lint format
.DEFAULT_GOAL := help

SHELL := /bin/bash
TESTS_DIR := tests

DISTRO ?=
FILTER ?=

help:
	@./main.sh help

all:
	@./main.sh all

# ── Tests ────────────────────────────────────────────────────────────────────

test:
	@./$(TESTS_DIR)/run-tests.sh $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-coverage:
	@./$(TESTS_DIR)/run-tests.sh --coverage $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-integration:
	@./$(TESTS_DIR)/run-tests.sh --integration $(if $(DISTRO),--distro=$(DISTRO)) $(if $(FILTER),--filter=$(FILTER))

test-unit:
	@./$(TESTS_DIR)/run-tests.sh --unit $(if $(FILTER),--filter=$(FILTER))

# ── Code Quality ─────────────────────────────────────────────────────────────

lint:
	@yarn lint:sh
	@yarn lint:bats

format:
	@yarn format

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/neovim /tmp/gitflow-installer /tmp/JetBrainsMono /tmp/JetBrainsMono.zip coverage
	@echo "✓ Clean completed"

# Catch-all: forward any target to ./main.sh
%:
	@./main.sh $@
