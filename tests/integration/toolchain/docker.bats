#!/usr/bin/env bats

# Integration tests for setup-docker.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/toolchain/setup-docker.sh
}

@test "docker binary is installed and responds to version" {
  run docker --version
  [ "$status" -eq 0 ]
}

@test "docker-compose is installed or available via plugin" {
  if command -v docker-compose >/dev/null 2>&1; then
    run docker-compose --version
    [ "$status" -eq 0 ]
  else
    run docker compose version
    [ "$status" -eq 0 ]
  fi
}

@test "docker group exists" {
  getent group docker
}

@test "setup-docker.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/toolchain/setup-docker.sh
  [ "$status" -eq 0 ]
}
