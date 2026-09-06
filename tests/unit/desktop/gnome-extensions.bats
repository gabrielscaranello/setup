#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-gnome-extensions.sh
}

teardown() {
  :
}

# ── Desktop Environment Skip Policy Tests ─────────────────────────────────────

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not GNOME). Skipping GNOME extensions setup." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'plasma' (not GNOME). Skipping GNOME extensions setup." ]]
}

# ── Environment & Version Detection Tests (SRP) ───────────────────────────────

@test "_get_gnome_shell_major_version fails when gnome-shell command is missing" {
  command() {
    if [ "$2" = "gnome-shell" ]; then return 1; fi
    builtin command "$@"
  }

  run _get_gnome_shell_major_version
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: gnome-shell is not installed or not found in PATH." ]]
}

@test "_get_gnome_shell_major_version fails when version cannot be determined" {
  gnome-shell() {
    echo "Unknown output without version"
  }
  command() {
    if [ "$2" = "gnome-shell" ]; then return 0; fi
    builtin command "$@"
  }

  run _get_gnome_shell_major_version
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: Unable to determine GNOME Shell major version." ]]
}

@test "_get_gnome_shell_major_version parses version correctly from gnome-shell" {
  gnome-shell() {
    echo "GNOME Shell 48.beta"
  }
  command() {
    if [ "$2" = "gnome-shell" ]; then return 0; fi
    builtin command "$@"
  }

  run _get_gnome_shell_major_version
  [ "$status" -eq 0 ]
  [ "$output" = "48" ]
}

@test "_get_installed_extension_version returns empty string if metadata does not exist" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _get_installed_extension_version "fake-uuid@test"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  rm -rf "$mock_home"
}

@test "_get_installed_extension_version returns version from user extension metadata.json" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  local ext_dir="$mock_home/.local/share/gnome-shell/extensions/test-uuid@domain"
  mkdir -p "$ext_dir"
  echo '{"name": "Test", "uuid": "test-uuid@domain", "version": 42}' > "$ext_dir/metadata.json"

  run _get_installed_extension_version "test-uuid@domain"
  [ "$status" -eq 0 ]
  [ "$output" = "42" ]
  rm -rf "$mock_home"
}

# ── Network & API Client Tests (SRP / DIP) ────────────────────────────────────

@test "_fetch_extension_api_data delegates to fetch_url with correct API URL" {
  fetch_url() {
    echo "fetched: $1"
  }

  run _fetch_extension_api_data "123" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "fetched: https://extensions.gnome.org/extension-info/?pk=123&shell_version=47" ]]
}

@test "_parse_api_field extracts fields from json" {
  local sample_json='{"name": "My Extension", "uuid": "my-ext@domain", "version": 15, "download_url": "/download/ext.zip"}'

  run _parse_api_field "$sample_json" "uuid"
  [ "$status" -eq 0 ]
  [ "$output" = "my-ext@domain" ]

  run _parse_api_field "$sample_json" "version"
  [ "$status" -eq 0 ]
  [ "$output" = "15" ]

  run _parse_api_field "$sample_json" "download_url"
  [ "$status" -eq 0 ]
  [ "$output" = "/download/ext.zip" ]
}

@test "_resolve_extension_url prepends domain to relative path and keeps absolute URLs" {
  run _resolve_extension_url "/download/ext.zip"
  [ "$status" -eq 0 ]
  [ "$output" = "https://extensions.gnome.org/download/ext.zip" ]

  run _resolve_extension_url "https://custom.domain/download/ext.zip"
  [ "$status" -eq 0 ]
  [ "$output" = "https://custom.domain/download/ext.zip" ]
}

# ── Official GNOME Extensions Tooling Tests (SRP) ─────────────────────────────

@test "_install_extension_archive invokes gnome-extensions install --force" {
  gnome-extensions() {
    if [ "$1" = "install" ] && [ "$2" = "--force" ]; then
      echo "installed: $3"
      return 0
    fi
    return 1
  }

  run _install_extension_archive "/tmp/dummy.zip"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: /tmp/dummy.zip" ]]
}

@test "_enable_extension invokes gnome-extensions enable" {
  gnome-extensions() {
    if [ "$1" = "enable" ]; then
      echo "enabled: $2"
      return 0
    fi
    return 1
  }

  run _enable_extension "sample@uuid"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "enabled: sample@uuid" ]]
}

@test "_download_and_install_extension handles download failures safely" {
  download_file() {
    return 1
  }

  run _download_and_install_extension "https://example.com/ext.zip" "uuid@test" "Test Ext"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to download extension package for 'Test Ext'." ]]
}

# ── Decision & Idempotency Logic Tests (SRP / OCP) ─────────────────────────────

@test "_should_update_extension returns true when local extension is not installed" {
  run _should_update_extension "" "45"
  [ "$status" -eq 0 ]
}

@test "_should_update_extension returns false when local version is equal or newer" {
  run _should_update_extension "45" "45"
  [ "$status" -eq 1 ]

  run _should_update_extension "46" "45"
  [ "$status" -eq 1 ]
}

@test "_should_update_extension returns true when local version is older" {
  run _should_update_extension "40" "45"
  [ "$status" -eq 0 ]
}

# ── Processing & Catalog Integration Tests (LSP / DIP) ────────────────────────

@test "_process_extension skips when api data cannot be fetched" {
  _fetch_extension_api_data() {
    echo ""
  }

  run _process_extension "999:uuid@test:Test Ext" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Could not fetch metadata from extensions.gnome.org for 'Test Ext'. Skipping." ]]
}

@test "_process_extension skips when download_url is missing" {
  _fetch_extension_api_data() {
    echo '{"name": "Test Ext", "uuid": "uuid@test", "version": 5, "download_url": null}'
  }

  run _process_extension "999:uuid@test:Test Ext" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Extension 'Test Ext' is not available for GNOME Shell 47. Skipping." ]]
}

@test "_process_extension skips download when extension is already up to date" {
  _fetch_extension_api_data() {
    echo '{"name": "Test Ext", "uuid": "uuid@test", "version": 5, "download_url": "/download.zip"}'
  }
  _get_installed_extension_version() {
    echo "5"
  }
  _enable_extension() {
    echo "enabled uuid@test"
  }

  run _process_extension "999:uuid@test:Test Ext" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Extension 'Test Ext' is already up to date (v5)." ]]
}

@test "_process_extension updates when newer version is available" {
  _fetch_extension_api_data() {
    echo '{"name": "Test Ext", "uuid": "uuid@test", "version": 6, "download_url": "/download.zip"}'
  }
  _get_installed_extension_version() {
    echo "4"
  }
  _download_and_install_extension() {
    echo "downloaded and installed $3"
    return 0
  }

  run _process_extension "999:uuid@test:Test Ext" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Updating 'Test Ext' (4 -> 6)..." ]]
  [[ "$output" =~ "downloaded and installed Test Ext" ]]
}

@test "_process_extension installs when extension is not installed" {
  _fetch_extension_api_data() {
    echo '{"name": "Test Ext", "uuid": "uuid@test", "version": 1, "download_url": "/download.zip"}'
  }
  _get_installed_extension_version() {
    echo ""
  }
  _download_and_install_extension() {
    echo "downloaded and installed $3"
    return 0
  }

  run _process_extension "999:uuid@test:Test Ext" "47"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing 'Test Ext' (v1)..." ]]
  [[ "$output" =~ "downloaded and installed Test Ext" ]]
}

@test "_get_target_extensions includes Arch extension on arch and excludes on others" {
  is_distro() {
    if [ "$1" = "arch" ]; then return 0; fi
    return 1
  }
  run _get_target_extensions
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1010:arch-update@RaphaelRochet:Arch Linux Updates Indicator" ]]

  is_distro() { return 1; }
  run _get_target_extensions
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "1010:arch-update@RaphaelRochet:Arch Linux Updates Indicator" ]]
}

@test "main executes extension loop when DE is gnome" {
  get_desktop_environment() { echo "gnome"; }
  _get_gnome_shell_major_version() { echo "47"; }
  _get_target_extensions() {
    echo "4269:AlphabeticalAppGrid@stuarthayhurst:Alphabetical App Grid"
  }
  _process_extension() {
    echo "processed $1"
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up GNOME Shell extensions..." ]]
  [[ "$output" =~ "Detected GNOME Shell major version: 47" ]]
  [[ "$output" =~ "processed 4269:AlphabeticalAppGrid@stuarthayhurst:Alphabetical App Grid" ]]
  [[ "$output" =~ "GNOME extensions setup completed successfully." ]]
  [[ "$output" =~ "Note: If you are running a Wayland session, please log out and log back in for new extensions to take effect." ]]
}
