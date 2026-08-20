#!/usr/bin/env bats

# Integration tests for setup-nvm.sh on Debian.

NVM_INIT='. "$HOME/.nvm/nvm.sh"'

setup_file() {
  bash /setup/scripts/setup-nvm.sh
}

@test "nvm is installed and responds to --version" {
  run bash -c "$NVM_INIT && nvm --version"
  [ "$status" -eq 0 ]
}

@test "node is installed and responds to --version" {
  run bash -c "$NVM_INIT && node --version"
  [ "$status" -eq 0 ]
}

@test "npm is installed and responds to --version" {
  run bash -c "$NVM_INIT && npm --version"
  [ "$status" -eq 0 ]
}

@test "yarn is installed and responds to --version" {
  run bash -c "$NVM_INIT && yarn --version"
  [ "$status" -eq 0 ]
}

@test "@github/copilot is installed globally" {
  run bash -c "$NVM_INIT && npm ls -g --depth 0 '@github/copilot'"
  [ "$status" -eq 0 ]
}

@test "@styled/typescript-styled-plugin is installed globally" {
  run bash -c "$NVM_INIT && npm ls -g --depth 0 '@styled/typescript-styled-plugin'"
  [ "$status" -eq 0 ]
}

@test "setup-nvm.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-nvm.sh
  [ "$status" -eq 0 ]
}

@test "nvm source is added exactly once to profile file" {
  local profile="$HOME/.bashrc"
  [ -f "$profile" ]
  count=$(grep -c 'export NVM_DIR=' "$profile" || true)
  [ "$count" -eq 1 ]
}
