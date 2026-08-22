#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE_ARCH="setup-test-archlinux"
IMAGE_DEBIAN="setup-test-debian"
IMAGE_FEDORA="setup-test-fedora"

COVERAGE=0
SELECTED_DISTRO=""
SELECTED_FILTER=""

_show_help() {
  echo "Usage: ./tests/run-tests.sh [options]"
  echo ""
  echo "Options:"
  echo "  --coverage            Generate code coverage reports with kcov"
  echo "  --distro=<name>       Run only on specific distro (archlinux|debian|fedora)"
  echo "  --filter=<pattern>    Run only tests matching pattern (e.g. nvm, neovim, utils)"
  echo "  -h, --help            Show this help message"
  echo ""
}

# Parse CLI arguments
for arg in "$@"; do
  case "$arg" in
    --coverage)
      COVERAGE=1
      ;;
    --distro=*)
      SELECTED_DISTRO="${arg#*=}"
      ;;
    --filter=*)
      SELECTED_FILTER="${arg#*=}"
      ;;
    -h|--help)
      _show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      _show_help >&2
      exit 1
      ;;
  esac
done

if [[ "${COVERAGE:-0}" == "1" ]]; then
  COVERAGE=1
fi

_check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed or not in PATH." >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Error: docker daemon is not running or current user lacks permissions." >&2
    exit 1
  fi
}

_detect_host_resources() {
  # Calculate 80% of host CPUs (using LC_ALL=C for dot notation)
  local total_cpus
  total_cpus="$(nproc 2>/dev/null || echo 1)"
  ALLOCATED_CPUS="$(LC_ALL=C awk -v c="$total_cpus" 'BEGIN { printf "%.2f", (c * 0.8 < 1 ? 1 : c * 0.8) }')"

  # Calculate 80% of total host RAM in bytes
  local total_mem_kb
  total_mem_kb="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)"
  if [[ "$total_mem_kb" -gt 0 ]]; then
    ALLOCATED_MEM_BYTES="$(LC_ALL=C awk -v m="$total_mem_kb" 'BEGIN { printf "%.0f", (m * 1024 * 0.8) }')"
    # Allocate up to 25% of the allocated memory for in-RAM /tmp compilation (min 512m)
    TMPFS_SIZE_M="$(LC_ALL=C awk -v m="$total_mem_kb" 'BEGIN { sz = int((m / 1024) * 0.25); printf "%dm", (sz < 512 ? 512 : sz) }')"
  else
    ALLOCATED_MEM_BYTES=""
    TMPFS_SIZE_M="1g"
  fi
}

_filter_tests() {
  local all_tests=("$@")
  local filtered=()
  for t in "${all_tests[@]}"; do
    if [[ -z "$SELECTED_FILTER" ]] || [[ "$t" =~ $SELECTED_FILTER ]]; then
      filtered+=("$t")
    fi
  done
  echo "${filtered[@]}"
}

_get_docker_resource_flags() {
  local flags=()
  if [[ -n "${ALLOCATED_CPUS:-}" ]]; then
    flags+=(--cpus="$ALLOCATED_CPUS")
  fi
  if [[ -n "${ALLOCATED_MEM_BYTES:-}" ]]; then
    flags+=(--memory="$ALLOCATED_MEM_BYTES")
  fi
  flags+=(
    --ipc=host
    --tmpfs "/tmp:rw,exec,size=${TMPFS_SIZE_M:-1g}"
    --ulimit "nofile=65535:65535"
  )
  echo "${flags[@]}"
}

_run_bats() {
  local image="$1"
  local distro="$2"
  shift 2
  local test_files=("$@")

  if [[ ${#test_files[@]} -eq 0 ]]; then
    echo "No matching tests found for distro: $distro (filter: $SELECTED_FILTER)"
    return 0
  fi

  local res_flags=()
  read -r -a res_flags <<< "$(_get_docker_resource_flags)"

  if [[ "$COVERAGE" -eq 1 ]]; then
    mkdir -p "coverage/$distro"
    docker run --rm \
      "${res_flags[@]}" \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      --user root \
      -v "$ROOT_DIR:/setup" \
      "$image" \
      kcov --include-path=/setup/scripts "/setup/coverage/$distro" /usr/local/bin/bats "${test_files[@]}"
  else
    docker run --rm \
      "${res_flags[@]}" \
      -v "$ROOT_DIR:/setup" \
      "$image" bats "${test_files[@]}"
  fi
}

HOST_USER="${USER:-$(id -un 2>/dev/null || echo "setupuser")}"

_test_archlinux() {
  echo "=== Testing on Arch Linux ==="
  docker build -q --build-arg USERNAME="$HOST_USER" -f tests/docker/archlinux.Dockerfile -t "$IMAGE_ARCH" . >/dev/null
  read -r -a tests <<< "$(_filter_tests tests/utils/utils-archlinux.bats tests/nvm/nvm-archlinux.bats tests/neovim/neovim-archlinux.bats)"
  if [[ ${#tests[@]} -gt 0 ]]; then
    _run_bats "$IMAGE_ARCH" "archlinux" "${tests[@]}"
  fi
}

_test_debian() {
  echo "=== Testing on Debian ==="
  docker build -q --build-arg USERNAME="$HOST_USER" -f tests/docker/debian.Dockerfile -t "$IMAGE_DEBIAN" . >/dev/null
  read -r -a tests <<< "$(_filter_tests tests/utils/utils-debian.bats tests/nvm/nvm-debian.bats tests/neovim/neovim-debian.bats)"
  if [[ ${#tests[@]} -gt 0 ]]; then
    _run_bats "$IMAGE_DEBIAN" "debian" "${tests[@]}"
  fi
}

_test_fedora() {
  echo "=== Testing on Fedora ==="
  docker build -q --build-arg USERNAME="$HOST_USER" -f tests/docker/fedora.Dockerfile -t "$IMAGE_FEDORA" . >/dev/null
  read -r -a tests <<< "$(_filter_tests tests/utils/utils-fedora.bats tests/nvm/nvm-fedora.bats tests/neovim/neovim-fedora.bats)"
  if [[ ${#tests[@]} -gt 0 ]]; then
    _run_bats "$IMAGE_FEDORA" "fedora" "${tests[@]}"
  fi
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
        dirs_to_merge=()
        for d in archlinux debian fedora; do
          if [[ -d "/setup/coverage/$d" ]]; then
            dirs_to_merge+=("/setup/coverage/$d")
          fi
        done
        if [[ ${#dirs_to_merge[@]} -gt 0 ]]; then
          kcov --merge /setup/coverage/merged "${dirs_to_merge[@]}"
          cp -r /setup/coverage/merged/kcov-merged/* /setup/coverage/
          rm -rf /setup/coverage/merged
          sed -i "s|\.\./data/bcov\.css|data/bcov.css|g" /setup/coverage/*.html 2>/dev/null || true
          chmod -R a+rwX /setup/coverage 2>/dev/null || true
        fi
      '
    echo "✓ Unified coverage report available at: coverage/index.html"
  fi
}

main() {
  _check_docker
  _detect_host_resources

  if [[ -n "$SELECTED_DISTRO" ]]; then
    case "$SELECTED_DISTRO" in
      archlinux|arch) _test_archlinux ;;
      debian)         _test_debian ;;
      fedora)         _test_fedora ;;
      *)
        echo "Unknown distro '$SELECTED_DISTRO'. Supported: archlinux, debian, fedora" >&2
        exit 1
        ;;
    esac
  else
    _test_archlinux
    echo ""
    _test_debian
    echo ""
    _test_fedora
  fi

  _merge_coverage
}

main "$@"
