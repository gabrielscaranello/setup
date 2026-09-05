#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/arch/_repositories.sh utility functions

setup() {
  source /setup/scripts/system/arch/_repositories.sh
}

@test "add_arch_multilib_repo skips when pacman.conf does not exist" {
  export PACMAN_CONF="/tmp/nonexistent-pacman-$$.conf"
  run add_arch_multilib_repo
  [ "$status" -eq 0 ]
}

@test "add_arch_multilib_repo skips when [multilib] is already enabled" {
  export PACMAN_CONF="/tmp/pacman-multilib-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  run add_arch_multilib_repo
  rm -f "$PACMAN_CONF"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Enabling multilib repository" ]]
}

@test "add_arch_multilib_repo uncomments [multilib] and updates pacman database" {
  export PACMAN_CONF="/tmp/pacman-commented-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist

#[multilib]
#Include = /etc/pacman.d/mirrorlist
EOF
  sudo() {
    "$@"
  }
  pacman() {
    echo "called pacman with: $*"
    return 0
  }
  run add_arch_multilib_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling multilib repository" ]]
  [[ "$output" =~ "called pacman with: -Sy" ]]
  grep -q "^\[multilib\]" "$PACMAN_CONF"
  grep -q "^Include = /etc/pacman.d/mirrorlist" "$PACMAN_CONF"
  rm -f "$PACMAN_CONF"
}

@test "add_arch_multilib_repo appends [multilib] when section is missing from pacman.conf" {
  export PACMAN_CONF="/tmp/pacman-missing-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist
EOF
  sudo() {
    "$@"
  }
  pacman() {
    echo "called pacman with: $*"
    return 0
  }
  run add_arch_multilib_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling multilib repository" ]]
  [[ "$output" =~ "called pacman with: -Sy" ]]
  grep -q "^\[multilib\]" "$PACMAN_CONF"
  grep -q "^Include = /etc/pacman.d/mirrorlist" "$PACMAN_CONF"
  rm -f "$PACMAN_CONF"
}
