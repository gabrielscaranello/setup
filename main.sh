#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

echo "================================"
echo "   Desktop Setup Script"
echo "================================"
echo ""

# Run Neovim setup
echo ">>> Running Neovim setup..."
echo ""
"$SCRIPTS_DIR/setup-neovim.sh"
echo ""
echo "✓ Neovim setup completed"
echo ""

echo "================================"
echo "   Setup Completed Successfully!"
echo "================================"
