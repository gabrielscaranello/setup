#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COVERAGE=0
SELECTED_DISTRO=""
SELECTED_FILTER=""
RUN_UNIT=0
RUN_INTEGRATION=0
PARALLEL=0

_show_help() {
  echo "Usage: ./tests/run-tests.sh [options]"
  echo ""
  echo "Options:"
  echo "  --unit                Run fast unit test suite only (mocked / logic tests)"
  echo "  --integration         Run container integration test suite only"
  echo "  --coverage            Generate code coverage reports with kcov"
  echo "  --parallel            Run integration test containers concurrently"
  echo "  --distro=<name>       Run integration tests only on specific distro (archlinux|debian|fedora|opensuse|tumbleweed|linuxmint)"
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
    --parallel)
      PARALLEL=1
      ;;
    --distro=*)
      SELECTED_DISTRO="${arg#*=}"
      ;;
    --filter=*)
      SELECTED_FILTER="${arg#*=}"
      ;;
    -h | --help)
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
  if ! command -v docker > /dev/null 2>&1; then
    echo "Error: docker is not installed or not in PATH." >&2
    exit 1
  fi
  if ! docker info > /dev/null 2>&1; then
    echo "Error: docker daemon is not running or current user lacks permissions." >&2
    exit 1
  fi
}

_detect_host_resources() {
  local total_cpus
  total_cpus="$(nproc 2> /dev/null || echo 1)"

  # Allow explicit environment override via DOCKER_CPUS.
  # If unset, do not set CFS bandwidth quota throttling (--cpus).
  # Leaving --cpus unconstrained allows the Linux CFS scheduler to dynamically
  # burst across 100% of available CPU cores on any machine architecture.
  if [[ -n "${DOCKER_CPUS:-}" ]]; then
    ALLOCATED_CPUS="$DOCKER_CPUS"
  else
    ALLOCATED_CPUS=""
  fi

  local total_mem_kb
  total_mem_kb="$(grep MemTotal /proc/meminfo 2> /dev/null | awk '{print $2}' || echo 0)"

  # Allow explicit environment override via DOCKER_MEMORY.
  # If unset, allow full host memory access without artificial cgroup caps.
  if [[ -n "${DOCKER_MEMORY:-}" ]]; then
    ALLOCATED_MEM_BYTES="$DOCKER_MEMORY"
  else
    ALLOCATED_MEM_BYTES=""
  fi

  if [[ -n "${DOCKER_TMPFS_SIZE:-}" ]]; then
    TMPFS_SIZE_M="$DOCKER_TMPFS_SIZE"
  elif [[ "$total_mem_kb" -gt 0 ]]; then
    # Dynamically allocate 25% of host memory to tmpfs (min 512m, max 8g)
    TMPFS_SIZE_M="$(LC_ALL=C awk -v m="$total_mem_kb" 'BEGIN { sz = int((m / 1024) * 0.25); if (sz < 512) sz = 512; if (sz > 8192) sz = 8192; printf "%dm", sz }')"
  else
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

_get_distro_cache_flags() {
  local distro="$1"
  local flags=()
  case "$distro" in
    archlinux | arch)
      flags+=(-v "setup-pkg-cache-archlinux:/var/cache/pacman/pkg")
      ;;
    debian)
      flags+=(-v "setup-pkg-cache-debian:/var/cache/apt/archives")
      ;;
    fedora)
      flags+=(-v "setup-pkg-cache-fedora:/var/cache/libdnf5" -v "setup-pkg-cache-fedora-legacy:/var/cache/dnf")
      ;;
    opensuse | leap)
      flags+=(-v "setup-pkg-cache-opensuse:/var/cache/zypp/packages")
      ;;
    tumbleweed)
      flags+=(-v "setup-pkg-cache-tumbleweed:/var/cache/zypp/packages")
      ;;
    linuxmint | mint)
      flags+=(-v "setup-pkg-cache-linuxmint:/var/cache/apt/archives")
      ;;
  esac
  echo "${flags[@]}"
}

_find_test_files() {
  local dir="$1"
  local target_distro="${2:-}"
  local files=()
  if [[ -d "$dir" ]]; then
    while IFS= read -r f; do
      if [[ -n "$target_distro" ]]; then
        case "$f" in
          */system/debian/*) [[ "$target_distro" == "debian" ]] || continue ;;
          */system/fedora/*) [[ "$target_distro" == "fedora" ]] || continue ;;
          */system/arch/*) [[ "$target_distro" == "archlinux" || "$target_distro" == "arch" ]] || continue ;;
          */system/opensuse/*) [[ "$target_distro" == "opensuse" || "$target_distro" == "tumbleweed" || "$target_distro" == "leap" ]] || continue ;;
          */system/linuxmint/*) [[ "$target_distro" == "linuxmint" || "$target_distro" == "mint" ]] || continue ;;
        esac
      fi

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

  local cache_flags=()
  read -r -a cache_flags <<< "$(_get_distro_cache_flags "$target_name")"

  if [[ "$COVERAGE" -eq 1 ]]; then
    rm -rf "coverage/$target_name"
    mkdir -p "coverage/$target_name"
    docker run --rm \
      "${res_flags[@]}" \
      "${cache_flags[@]}" \
      --ulimit "nofile=1024:1024" \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      -w /setup \
      -v "$ROOT_DIR:/setup" \
      "$image" \
      kcov --include-path=/setup/scripts "/setup/coverage/$target_name" /usr/local/bin/bats "${test_files[@]}"
  else
    docker run --rm \
      "${res_flags[@]}" \
      "${cache_flags[@]}" \
      -w /setup \
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
  if [[ "$COVERAGE" -eq 0 ]] && command -v bats > /dev/null 2>&1; then
    echo "Running unit tests directly on host..."
    # Create a /setup symlink or execute directly with /setup aliased
    if [[ ! -e /setup ]]; then
      sudo ln -s "$ROOT_DIR" /setup 2> /dev/null || true
    fi
    if [[ -e /setup ]]; then
      bats "${unit_tests[@]}"
      return 0
    fi
  fi

  # Otherwise run inside a lightweight Debian image
  local image="setup-test-debian"
  if ! docker image inspect "$image" > /dev/null 2>&1; then
    docker build -q --build-arg USERNAME="$HOST_USER" -f tests/docker/debian.Dockerfile -t "$image" tests/docker > /dev/null
  fi
  _run_bats_container "$image" "unit" "${unit_tests[@]}"
}

_run_integration_distro() {
  local distro="$1"
  local dockerfile="tests/docker/${distro}.Dockerfile"
  local image="setup-test-${distro}"

  echo "=== Running Integration Tests on ${distro^} ==="
  if ! docker image inspect "$image" > /dev/null 2>&1; then
    docker build -q --build-arg USERNAME="$HOST_USER" -f "$dockerfile" -t "$image" tests/docker > /dev/null
  fi

  local integration_tests=()
  read -r -a integration_tests <<< "$(_find_test_files tests/integration "$distro")"

  if [[ ${#integration_tests[@]} -gt 0 ]]; then
    _run_bats_container "$image" "$distro" "${integration_tests[@]}"
  fi
}

_run_all_integration_parallel() {
  local distros=("archlinux" "debian" "fedora" "opensuse" "tumbleweed" "linuxmint")
  local log_dir
  log_dir="$(mktemp -d "${TMPDIR:-/tmp}/setup-tests-parallel.XXXXXX")"
  local pids=()
  local distro_names=()

  echo "=== Running Integration Tests Concurrently Across All Distros ==="
  echo "Distros running in parallel: ${distros[*]}"
  echo ""

  for d in "${distros[@]}"; do
    (
      _run_integration_distro "$d" > "${log_dir}/${d}.log" 2>&1
    ) &
    pids+=($!)
    distro_names+=("$d")
  done

  local exit_code=0
  for i in "${!pids[@]}"; do
    local pid="${pids[$i]}"
    local d="${distro_names[$i]}"
    if ! wait "$pid"; then
      echo "❌ Integration tests FAILED on ${d^}!"
      cat "${log_dir}/${d}.log"
      exit_code=1
    else
      echo "✓ Integration tests PASSED on ${d^}."
      tail -n 10 "${log_dir}/${d}.log"
    fi
    echo ""
  done

  rm -rf "$log_dir"
  return "$exit_code"
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
        for d in unit archlinux debian fedora opensuse tumbleweed linuxmint; do
          if [[ -d "/setup/coverage/$d" ]]; then
            while IFS= read -r cov_db_dir; do
              dirs_to_merge+=("$cov_db_dir")
            done < <(find "/setup/coverage/$d" -name "coverage.db" -exec dirname {} \; | sort -u)
          fi
        done
        if [[ ${#dirs_to_merge[@]} -eq 1 ]]; then
          cp -r "${dirs_to_merge[0]}"/* /setup/coverage/
          sed -i "s|\.\./data/bcov\.css|data/bcov.css|g" /setup/coverage/*.html 2>/dev/null || true
          chmod -R a+rwX /setup/coverage 2>/dev/null || true
        elif [[ ${#dirs_to_merge[@]} -gt 1 ]]; then
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

HOST_USER="${USER:-$(id -un 2> /dev/null || echo "setupuser")}"

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
        archlinux | arch) _run_integration_distro "archlinux" ;;
        debian) _run_integration_distro "debian" ;;
        fedora) _run_integration_distro "fedora" ;;
        opensuse | leap | suse) _run_integration_distro "opensuse" ;;
        tumbleweed) _run_integration_distro "tumbleweed" ;;
        linuxmint | mint) _run_integration_distro "linuxmint" ;;
        *)
          echo "Unknown distro '$SELECTED_DISTRO'. Supported: archlinux, debian, fedora, opensuse, tumbleweed, linuxmint" >&2
          exit 1
          ;;
      esac
    elif [[ "$PARALLEL" -eq 1 ]]; then
      _run_all_integration_parallel
    else
      _run_integration_distro "archlinux"
      echo ""
      _run_integration_distro "debian"
      echo ""
      _run_integration_distro "fedora"
      echo ""
      _run_integration_distro "opensuse"
      echo ""
      _run_integration_distro "tumbleweed"
    fi
  fi

  _merge_coverage
}

main "$@"
