#!/bin/bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

main() {
  echo "================================"
  echo "   Desktop Setup Script"
  echo "================================"
  echo ""

  echo ">>> Running Docker setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-docker.sh"
  echo ""
  echo "✓ Docker setup completed"
  echo ""

  echo ">>> Running Firefox setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-firefox.sh"
  echo ""
  echo "✓ Firefox setup completed"
  echo ""

  echo ">>> Running Fonts setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-fonts.sh"
  echo ""
  echo "✓ Fonts setup completed"
  echo ""

  echo ">>> Running Gitflow setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-gitflow.sh"
  echo ""
  echo "✓ Gitflow setup completed"
  echo ""

  echo ">>> Running Golang setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-go.sh"
  echo ""
  echo "✓ Golang setup completed"
  echo ""

  echo ">>> Running NVM/Node setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-nvm.sh"
  echo ""
  echo "✓ NVM/Node setup completed"
  echo ""

  echo ">>> Running Neovim setup..."
  echo ""
  bash "$SCRIPTS_DIR/setup-neovim.sh"
  echo ""
  echo "✓ Neovim setup completed"
  echo ""

  echo "================================"
  echo "   Setup Completed Successfully!"
  echo "================================"
}

main "$@"
