#!/bin/bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

main() {
  echo "================================"
  echo "   Desktop Setup Script"
  echo "================================"
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
