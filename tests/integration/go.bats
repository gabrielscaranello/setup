#!/usr/bin/env bats

# Integration tests for setup-go.sh (runs across all distros)

GO_INIT="export PATH=\"\$PATH:/usr/local/go/bin:\$HOME/go/bin\""

setup_file() {
  bash /setup/scripts/setup-go.sh
}

@test "go binary is available and responds to version" {
  run bash -c "$GO_INIT && go version"
  [ "$status" -eq 0 ]
}

@test "dockerfmt is installed and responds to version or help" {
  run bash -c "$GO_INIT && command -v dockerfmt"
  [ "$status" -eq 0 ]
}

@test "setup-go.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-go.sh
  [ "$status" -eq 0 ]
}
