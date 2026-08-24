#!/usr/bin/env bats

# Integration tests for scripts/debian/setup-kernel.sh

setup_file() {
  bash /setup/scripts/debian/setup-kernel.sh
}

@test "setup-kernel.sh executes successfully" {
  run bash /setup/scripts/debian/setup-kernel.sh
  [ "$status" -eq 0 ]
}

@test "backports repository is configured on Debian" {
  if command -v apt >/dev/null 2>&1; then
    run bash -c "grep -Er 'backports' /etc/apt/sources.list* 2>/dev/null"
    [ "$status" -eq 0 ]
  fi
}

@test "installed kernel packages correspond to the latest backports version rather than base LTS" {
  if command -v apt >/dev/null 2>&1; then
    # Verify package is installed
    run dpkg -s linux-image-amd64
    [ "$status" -eq 0 ]

    # Retrieve installed version and available versions from apt-cache
    local installed_version base_lts_version backports_version
    installed_version="$(dpkg-query -W -f='${Version}' linux-image-amd64 2>/dev/null)"
    
    # Check if backports repository contains a candidate for this distro suite
    backports_version="$(apt-cache madison linux-image-amd64 | grep 'backports' | awk '{print $3}' | head -n1 || true)"
    base_lts_version="$(apt-cache madison linux-image-amd64 | grep -v 'backports' | awk '{print $3}' | head -n1 || true)"

    if [ -n "$backports_version" ]; then
      # If backports is available (e.g. on stable releases), installed version must match backports and differ from default base LTS
      [ "$installed_version" = "$backports_version" ]
      
      if [ -n "$base_lts_version" ]; then
        # Ensure installed version is strictly newer (or different) from base LTS
        [ "$installed_version" != "$base_lts_version" ]
        run dpkg --compare-versions "$installed_version" "gt" "$base_lts_version"
        [ "$status" -eq 0 ]
      fi
    fi
  fi
}
