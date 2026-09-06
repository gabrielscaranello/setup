#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/_dconf.sh
}

teardown() {
  :
}

# ── ensure_dconf Tests ────────────────────────────────────────────────────────

@test "ensure_dconf succeeds when dconf command is available" {
  command() {
    if [ "$2" = "dconf" ]; then return 0; fi
    builtin command "$@"
  }

  run ensure_dconf
  [ "$status" -eq 0 ]
}

@test "ensure_dconf attempts to install dconf when initially missing" {
  local flag_file
  flag_file="$(mktemp /tmp/dconf_installed_XXXXXX)"
  rm -f "$flag_file"

  command() {
    if [ "$2" = "dconf" ]; then
      if [ -f "$flag_file" ]; then return 0; fi
      return 1
    fi
    builtin command "$@"
  }
  install_packages() {
    echo "install_packages called: $*"
    touch "$flag_file"
  }

  run ensure_dconf
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf not found in PATH, attempting to install..." ]]
  [[ "$output" =~ "install_packages called: dconf" ]]
  rm -f "$flag_file"
}

@test "ensure_dconf fails when dconf cannot be found or installed" {
  command() {
    if [ "$2" = "dconf" ]; then return 1; fi
    builtin command "$@"
  }
  install_packages() {
    return 1
  }

  run ensure_dconf
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: dconf CLI is not installed or not found in PATH." ]]
}

# ── dconf_exec Tests ──────────────────────────────────────────────────────────

@test "dconf_exec uses dbus-run-session when session address is empty and tool exists" {
  export DBUS_SESSION_BUS_ADDRESS=""
  command() {
    if [ "$2" = "dbus-run-session" ]; then return 0; fi
    builtin command "$@"
  }
  dbus-run-session() {
    echo "dbus-run-session called with: $*"
  }

  run dconf_exec read /some/key
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dbus-run-session called with: -- dconf read /some/key" ]]
}

@test "dconf_exec invokes dconf directly when DBUS_SESSION_BUS_ADDRESS is present" {
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
  dconf() {
    echo "dconf called with: $*"
  }

  run dconf_exec read /some/key
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf called with: read /some/key" ]]
}

@test "dconf_exec invokes dconf directly when dbus-run-session is not available" {
  export DBUS_SESSION_BUS_ADDRESS=""
  command() {
    if [ "$2" = "dbus-run-session" ]; then return 1; fi
    builtin command "$@"
  }
  dconf() {
    echo "dconf called with: $*"
  }

  run dconf_exec read /some/key
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf called with: read /some/key" ]]
}

# ── load_dconf_file Tests ─────────────────────────────────────────────────────

@test "load_dconf_file warns and returns 0 when file does not exist" {
  run load_dconf_file "/non/existent/path/test.dconf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Warning: Configuration file '/non/existent/path/test.dconf' not found. Skipping." ]]
}

@test "load_dconf_file executes dconf_exec load with valid file" {
  local mock_file
  mock_file="$(mktemp /tmp/test_dconf_helper_XXXXXX.dconf)"
  echo "[test/section]" > "$mock_file"

  dconf_exec() {
    echo "dconf_exec called: $*"
  }

  run load_dconf_file "$mock_file"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Loading dconf configuration: $(basename "$mock_file")..." ]]
  [[ "$output" =~ "dconf_exec called: load /" ]]
  rm -f "$mock_file"
}

# ── load_dconf_files Tests ────────────────────────────────────────────────────

@test "load_dconf_files fails if base directory does not exist" {
  run load_dconf_files "/non/existent/dir" "file1.dconf" "file2.dconf"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: Configuration directory '/non/existent/dir' not found." ]]
}

@test "load_dconf_files iterates through all files in base directory" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/dconf_batch_XXXXXX)"

  load_dconf_file() {
    echo "loading file: $(basename "$1")"
  }

  run load_dconf_files "$mock_dir" "file1.dconf" "file2.dconf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "loading file: file1.dconf" ]]
  [[ "$output" =~ "loading file: file2.dconf" ]]

  rm -rf "$mock_dir"
}
