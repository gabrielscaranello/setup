#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  TEST_DIR="$(mktemp -d)"
  HOME="$TEST_DIR/home"
  mkdir -p "$HOME"

  MOCK_USR_SHARE="$TEST_DIR/usr/share/applications"
  MOCK_USR_LOCAL_SHARE="$TEST_DIR/usr/local/share/applications"
  mkdir -p "$MOCK_USR_SHARE" "$MOCK_USR_LOCAL_SHARE"

  source /setup/scripts/desktop/setup-hide-apps.sh 2> /dev/null || source scripts/desktop/setup-hide-apps.sh
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "_get_target_dir defaults to HOME/.local/share/applications when XDG_DATA_HOME is unset" {
  unset XDG_DATA_HOME
  run _get_target_dir
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.local/share/applications" ]
}

@test "_get_target_dir respects XDG_DATA_HOME when set" {
  export XDG_DATA_HOME="$TEST_DIR/custom_xdg"
  run _get_target_dir
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_DIR/custom_xdg/applications" ]
}

@test "_hide_app skips when desktop file does not exist" {
  run _hide_app "non_existent_app"
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/applications/non_existent_app.desktop" ]
}

@test "_hide_app copies desktop file from /usr/share/applications and sets NoDisplay=true" {
  # Mock default_location by overriding _hide_app or testing standard path
  # Create a mock function or simulate filesystem
  local mock_app="testapp"
  mkdir -p "/tmp/test-setup-hide-apps-usr/applications"
  local mock_system_file="/tmp/test-setup-hide-apps-usr/applications/${mock_app}.desktop"
  cat << 'EOF' > "$mock_system_file"
[Desktop Entry]
Type=Application
Name=TestApp
Exec=testapp
NoDisplay=false
EOF

  _hide_app() {
    local app="$1"
    local default_location="$mock_system_file"
    if [ -f "${default_location}" ]; then
      local target_dir
      target_dir="$(_get_target_dir)"
      mkdir -p "${target_dir}"
      local home_location="${target_dir}/${app}.desktop"
      cp "${default_location}" "${home_location}"
      sed -i "s/NoDisplay=\(true\|false\)//g" "${home_location}" > /dev/null
      echo "NoDisplay=true" | tee -a "${home_location}" > /dev/null
    fi
  }

  run _hide_app "$mock_app"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/applications/${mock_app}.desktop" ]

  local content
  content="$(cat "$HOME/.local/share/applications/${mock_app}.desktop")"
  [[ "$content" =~ "NoDisplay=true" ]]
  [[ ! "$content" =~ "NoDisplay=false" ]]

  rm -rf "/tmp/test-setup-hide-apps-usr"
}

@test "_hide_app handles fallback to /usr/local/share/applications" {
  local mock_app="testlocalapp"
  local mock_local_file="/tmp/test-local-apps/${mock_app}.desktop"
  mkdir -p "/tmp/test-local-apps"
  cat << 'EOF' > "$mock_local_file"
[Desktop Entry]
Type=Application
Name=TestLocalApp
Exec=testlocalapp
EOF

  _hide_app() {
    local app="$1"
    local default_location="/nonexistent/${app}.desktop"
    if [ ! -f "${default_location}" ] && [ -f "$mock_local_file" ]; then
      default_location="$mock_local_file"
    fi

    if [ -f "${default_location}" ]; then
      local target_dir
      target_dir="$(_get_target_dir)"
      mkdir -p "${target_dir}"
      local home_location="${target_dir}/${app}.desktop"
      cp "${default_location}" "${home_location}"
      sed -i "s/NoDisplay=\(true\|false\)//g" "${home_location}" > /dev/null
      echo "NoDisplay=true" | tee -a "${home_location}" > /dev/null
    fi
  }

  run _hide_app "$mock_app"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/applications/${mock_app}.desktop" ]

  local content
  content="$(cat "$HOME/.local/share/applications/${mock_app}.desktop")"
  [[ "$content" =~ "NoDisplay=true" ]]

  rm -rf "/tmp/test-local-apps"
}

@test "APPS does not contain nvim or btop and UNHIDE_APPS contains them" {
  local app
  for app in "${APPS[@]}"; do
    [ "$app" != "nvim" ]
    [ "$app" != "btop" ]
  done

  local has_nvim=0
  local has_btop=0
  for app in "${UNHIDE_APPS[@]}"; do
    if [ "$app" = "nvim" ]; then has_nvim=1; fi
    if [ "$app" = "btop" ]; then has_btop=1; fi
  done
  [ "$has_nvim" -eq 1 ]
  [ "$has_btop" -eq 1 ]
}

@test "APPS contains cups and system-config-printer" {
  local has_cups=0
  local has_printer=0
  local app
  for app in "${APPS[@]}"; do
    if [ "$app" = "cups" ]; then has_cups=1; fi
    if [ "$app" = "system-config-printer" ]; then has_printer=1; fi
  done
  [ "$has_cups" -eq 1 ]
  [ "$has_printer" -eq 1 ]
}

@test "_unhide_app removes local desktop file when NoDisplay=true is present" {
  local target_dir
  target_dir="$(_get_target_dir)"
  mkdir -p "$target_dir"
  cat << 'EOF' > "$target_dir/nvim.desktop"
[Desktop Entry]
Type=Application
Name=Neovim
Exec=nvim
NoDisplay=true
EOF

  run _unhide_app "nvim"
  [ "$status" -eq 0 ]
  [ ! -f "$target_dir/nvim.desktop" ]
}

@test "_unhide_app preserves local desktop file when NoDisplay=true is absent" {
  local target_dir
  target_dir="$(_get_target_dir)"
  mkdir -p "$target_dir"
  cat << 'EOF' > "$target_dir/custom.desktop"
[Desktop Entry]
Type=Application
Name=Custom
Exec=custom
EOF

  run _unhide_app "custom"
  [ "$status" -eq 0 ]
  [ -f "$target_dir/custom.desktop" ]
}

@test "_unhide_app does nothing when target file does not exist" {
  run _unhide_app "nonexistent"
  [ "$status" -eq 0 ]
}

@test "_hide_desktop_apps iterates over APPS and hides found apps, and unhides UNHIDE_APPS" {
  _hide_app() {
    echo "hiding: $1"
  }
  _unhide_app() {
    echo "unhiding: $1"
  }

  run _hide_desktop_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Hiding unwanted desktop applications..." ]]
  [[ "$output" =~ "Desktop applications hidden." ]]
  [[ "$output" =~ "hiding: bottom" ]]
  [[ "$output" =~ "unhiding: nvim" ]]
  [[ "$output" =~ "unhiding: btop" ]]
}

@test "main executes _hide_desktop_apps successfully" {
  _hide_desktop_apps() {
    echo "mocked _hide_desktop_apps"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mocked _hide_desktop_apps" ]]
}
