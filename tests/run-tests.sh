#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE_ARCH="setup-test-archlinux"
IMAGE_DEBIAN="setup-test-debian"
IMAGE_FEDORA="setup-test-fedora"

_test_archlinux() {
  echo "=== Testing on Arch Linux ==="
  docker build -f tests/docker/archlinux.Dockerfile -t "$IMAGE_ARCH" .
  docker run --rm "$IMAGE_ARCH" bats tests/nvm/nvm-archlinux.bats tests/neovim/neovim-archlinux.bats
}

_test_debian() {
  echo "=== Testing on Debian ==="
  docker build -f tests/docker/debian.Dockerfile -t "$IMAGE_DEBIAN" .
  docker run --rm "$IMAGE_DEBIAN" bats tests/nvm/nvm-debian.bats tests/neovim/neovim-debian.bats
}

_test_fedora() {
  echo "=== Testing on Fedora ==="
  docker build -f tests/docker/fedora.Dockerfile -t "$IMAGE_FEDORA" .
  docker run --rm "$IMAGE_FEDORA" bats tests/nvm/nvm-fedora.bats tests/neovim/neovim-fedora.bats
}

main() {
  _test_archlinux
  echo ""
  _test_debian
  echo ""
  _test_fedora
}

main "$@"
