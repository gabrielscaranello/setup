#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COVERAGE=0
SELECTED_DISTRO=""
SELECTED_FILTER=""
RUN_UNIT=0
RUN_INTEGRATION=0

_show_help() {
  echo "Usage: ./tests/run-tests.sh [options]"
  echo ""
  echo "Options:"
  echo "  --unit                Run fast unit test suite only (mocked / logic tests)"
  echo "  --integration         Run container integration test suite only"
  echo "  --coverage            Generate code coverage reports with kcov"
  echo "  --distro=<name>       Run integration tests only on specific distro (archlinux|debian|fedora)"
  echo "  --filter=<pattern>    Run only tests matching pattern (e.g. nvm, neovim, utils)"
  echo "  -h, --help            Show this help message"
  echo ""
}

# Parse CLI arguments
for arg in "$@"; do
  case "$arg" in
    --unit)
      RUN_UNIT=1
      ;;
    --integration)
      RUN_INTEGRATION=1
      ;;
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

# Default: if neither --unit nor --integration is explicitly given, run both
if [[ "$RUN_UNIT" -eq 0 && "$RUN_INTEGRATION" -eq 0 ]]; then
  RUN_UNIT=1
  RUN_INTEGRATION=1
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
  local total_cpus
  total_cpus="$(nproc 2>/dev/null || echo 1)"
  ALLOCATED_CPUS="$(LC_ALL=C awk -v c="$total_cpus" 'BEGIN { printf "%.2f", (c * 0.8 < 1 ? 1 : c * 0.8) }')"

  local total_mem_kb
  total_mem_kb="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)"
  if [[ "$total_mem_kb" -gt 0 ]]; then
    ALLOCATED_MEM_BYTES="$(LC_ALL=C awk -v m="$total_mem_kb" 'BEGIN { printf "%.0f", (m * 1024 * 0.8) }')"
    TMPFS_SIZE_M="$(LC_ALL=C awk -v m="$total_mem_kb" 'BEGIN { sz = int((m / 1024) * 0.25); printf "%dm", (sz < 512 ? 512 : sz) }')"
  else
    ALLOCATED_MEM_BYTES=""
    TMPFS_SIZE_M="1g"
  fi
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

_find_test_files() {
  local dir="$1"
  local files=()
  if [[ -d "$dir" ]]; then
    while IFS= read -r f; do
      if [[ -z "$SELECTED_FILTER" ]] || [[ "$f" =~ $SELECTED_FILTER ]]; then
        files+=("$f")
      fi
    done < <(find "$dir" -name "*.bats" | sort)
  fi
  echo "${files[@]}"
}

_run_bats_container() {
  local image="$1"
  local target_name="$2"
  shift 2
  local test_files=("$@")

  if [[ ${#test_files[@]} -eq 0 ]]; then
    echo "No matching tests found for $target_name (filter: $SELECTED_FILTER)"
    return 0
  fi

  local res_flags=()
  read -r -a res_flags <<< "$(_get_docker_resource_flags)"

  if [[ "$COVERAGE" -eq 1 ]]; then
    mkdir -p "coverage/$target_name"
    docker run --rm \
      "${res_flags[@]}" \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      --user root \
      -v "$ROOT_DIR:/setup" \
      "$image" \
      kcov --include-path=/setup/scripts "/setup/coverage/$target_name" /usr/local/bin/bats "${test_files[@]}"
  else
    docker run --rm \
      "${res_flags[@]}" \
      -v "$ROOT_DIR:/setup" \
      "$image" bats "${test_files[@]}"
  fi
}

_run_unit_tests() {
  echo "=== Running Unit Tests ==="
  local unit_tests=()
  read -r -a unit_tests <<< "$(_find_test_files tests/unit)"

  if [[ ${#unit_tests[@]} -eq 0 ]]; then
    echo "No unit tests match filter: $SELECTED_FILTER"
    return 0
  fi

  # If bats is locally available and coverage is not requested, run directly for extreme speed
  if [[ "$COVERAGE" -eq 0 ]] && command -v bats >/dev/null 2>&1; then
    echo "Running unit tests directly on host..."
    # Create a /setup symlink or execute directly with /setup aliased
    if [[ ! -e /setup ]]; then
      sudo ln -s "$ROOT_DIR" /setup 2>/dev/null || true
    fi
    if [[ -e /setup ]]; then
      bats "${unit_tests[@]}"
      return 0
    fi
  fi

  # Otherwise run inside a lightweight Debian image
  local image="setup-test-debian"
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build -q --build-arg USERNAME="$HOST_USER" -f tests/docker/debian.Dockerfile -t "$image" tests/docker >/dev/null
  fi
  _run_bats_container "$image" "unit" "${unit_tests[@]}"
}

_run_integration_distro() {
  local distro="$1"
  local dockerfile="tests/docker/${distro}.Dockerfile"
  local image="setup-test-${distro}"

  echo "=== Running Integration Tests on ${distro^} ==="
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build -q --build-arg USERNAME="$HOST_USER" -f "$dockerfile" -t "$image" tests/docker >/dev/null
  fi

  local integration_tests=()
  read -r -a integration_tests <<< "$(_find_test_files tests/integration)"

  if [[ ${#integration_tests[@]} -gt 0 ]]; then
    _run_bats_container "$image" "$distro" "${integration_tests[@]}"
  fi
}

_merge_coverage() {
  if [[ "$COVERAGE" -eq 1 ]]; then
    echo ""
    echo "=== Unifying Code Coverage Reports ==="
    local image="setup-test-debian"
    docker run --rm \
      --ulimit nofile=1024:1024 \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      --user root \
      -v "$ROOT_DIR/coverage:/setup/coverage" \
      "$image" \
      bash -c '
        dirs_to_merge=()
        for d in unit archlinux debian fedora; do
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

HOST_USER="${USER:-$(id -un 2>/dev/null || echo "setupuser")}"

main() {
  _check_docker
  _detect_host_resources

  if [[ "$RUN_UNIT" -eq 1 && -z "$SELECTED_DISTRO" ]]; then
    _run_unit_tests
    echo ""
  fi

  if [[ "$RUN_INTEGRATION" -eq 1 ]]; then
    if [[ -n "$SELECTED_DISTRO" ]]; then
      case "$SELECTED_DISTRO" in
        archlinux|arch) _run_integration_distro "archlinux" ;;
        debian)         _run_integration_distro "debian" ;;
        fedora)         _run_integration_distro "fedora" ;;
        *)
          echo "Unknown distro '$SELECTED_DISTRO'. Supported: archlinux, debian, fedora" >&2
          exit 1
          ;;
      esac
    else
      _run_integration_distro "archlinux"
      echo ""
      _run_integration_distro "debian"
      echo ""
      _run_integration_distro "fedora"
    fi
  fi

  _merge_coverage
}

main "$@"
