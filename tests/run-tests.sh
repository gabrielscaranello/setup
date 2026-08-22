#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE_ARCH="setup-test-archlinux"
IMAGE_DEBIAN="setup-test-debian"
IMAGE_FEDORA="setup-test-fedora"

COVERAGE=0
if [[ "${1:-}" == "--coverage" ]] || [[ "${COVERAGE:-0}" == "1" ]]; then
  COVERAGE=1
fi

_run_bats() {
  local image="$1"
  local distro="$2"
  shift 2
  local test_files=("$@")

  if [[ "$COVERAGE" -eq 1 ]]; then
    mkdir -p "coverage/$distro"
    docker run --rm \
      --ulimit nofile=1024:1024 \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      --user root \
      -v "$ROOT_DIR/coverage/$distro:/setup/coverage" \
      "$image" \
      kcov --include-path=/setup/scripts /setup/coverage /usr/local/bin/bats "${test_files[@]}"
  else
    docker run --rm "$image" bats "${test_files[@]}"
  fi
}

_test_archlinux() {
  echo "=== Testing on Arch Linux ==="
  docker build -f tests/docker/archlinux.Dockerfile -t "$IMAGE_ARCH" .
  _run_bats "$IMAGE_ARCH" "archlinux" tests/utils/utils-archlinux.bats tests/nvm/nvm-archlinux.bats tests/neovim/neovim-archlinux.bats
}

_test_debian() {
  echo "=== Testing on Debian ==="
  docker build -f tests/docker/debian.Dockerfile -t "$IMAGE_DEBIAN" .
  _run_bats "$IMAGE_DEBIAN" "debian" tests/utils/utils-debian.bats tests/nvm/nvm-debian.bats tests/neovim/neovim-debian.bats
}

_test_fedora() {
  echo "=== Testing on Fedora ==="
  docker build -f tests/docker/fedora.Dockerfile -t "$IMAGE_FEDORA" .
  _run_bats "$IMAGE_FEDORA" "fedora" tests/utils/utils-fedora.bats tests/nvm/nvm-fedora.bats tests/neovim/neovim-fedora.bats
}

_merge_coverage() {
  if [[ "$COVERAGE" -eq 1 ]]; then
    echo ""
    echo "=== Unifying Code Coverage Reports ==="
    docker run --rm \
      --ulimit nofile=1024:1024 \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      --user root \
      -v "$ROOT_DIR/coverage:/setup/coverage" \
      "$IMAGE_DEBIAN" \
      bash -c '
        kcov --merge /setup/coverage/merged /setup/coverage/archlinux /setup/coverage/debian /setup/coverage/fedora
        cp -r /setup/coverage/merged/kcov-merged/* /setup/coverage/
        rm -rf /setup/coverage/merged
        sed -i "s|\.\./data/bcov\.css|data/bcov.css|g" /setup/coverage/*.html 2>/dev/null || true
        chmod -R a+rwX /setup/coverage 2>/dev/null || true
      '
    echo "✓ Unified coverage report available at: coverage/index.html"
  fi
}

main() {
  _test_archlinux
  echo ""
  _test_debian
  echo ""
  _test_fedora
  _merge_coverage
}

main "$@"
