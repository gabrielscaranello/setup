#!/usr/bin/env bats

# Integration tests for setup-vscodium.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/apps/setup-vscodium.sh
}

@test "vscodium / code is installed and configured according to distribution" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  if [ "$pm" = "pacman" ]; then
    command -v code >/dev/null 2>&1
  elif [ "$pm" = "dnf" ]; then
    [ -f /etc/yum.repos.d/vscodium.repo ]
    command -v codium >/dev/null 2>&1
  elif [ "$pm" = "apt" ]; then
    [ -f /etc/apt/sources.list.d/vscodium.sources ]
    [ -f /usr/share/keyrings/vscodium-archive-keyring.gpg ]
    command -v codium >/dev/null 2>&1
  fi
}

@test "setup-vscodium.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-vscodium.sh
  [ "$status" -eq 0 ]
}
