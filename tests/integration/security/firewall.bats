#!/usr/bin/env bats

setup_file() {
  bash /setup/scripts/security/setup-firewall.sh
}

@test "firewall package (ufw or firewalld) is installed and command exists" {
  if command -v dnf >/dev/null 2>&1; then
    command -v firewall-cmd
  else
    command -v ufw
  fi
}

@test "setup-firewall.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/security/setup-firewall.sh
  [ "$status" -eq 0 ]
}
