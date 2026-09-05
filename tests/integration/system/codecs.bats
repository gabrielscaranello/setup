#!/usr/bin/env bats

@test "setup-codecs.sh completes successfully across all distros" {
  run bash /setup/scripts/system/setup-codecs.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Codecs installed successfully!" ]]
}

@test "setup-codecs.sh is idempotent" {
  # Run once to ensure installed
  bash /setup/scripts/system/setup-codecs.sh
  
  # Run second time and ensure success
  run bash /setup/scripts/system/setup-codecs.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Codecs installed successfully!" ]]
}
