#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/_plasma.sh
}

teardown() {
  :
}

# ── ensure_kwriteconfig Tests ─────────────────────────────────────────────────

@test "ensure_kwriteconfig skips installation when kwriteconfig6 exists" {
  command() {
    if [ "$2" = "kwriteconfig6" ]; then return 0; fi
    builtin command "$@"
  }
  install_packages() {
    echo "install_packages called"
    return 0
  }

  run ensure_kwriteconfig
  [ "$status" -eq 0 ]
  [[ "$output" != *"install_packages called"* ]]
}

@test "ensure_kwriteconfig attempts to install when kwriteconfig6 is missing" {
  command() {
    if [ "$2" = "kwriteconfig6" ]; then return 1; fi
    builtin command "$@"
  }
  install_packages() {
    echo "install_packages called: $*"
    return 0
  }

  run ensure_kwriteconfig
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kwriteconfig6 not found in PATH, attempting to install..." ]]
  [[ "$output" =~ "install_packages called: kwriteconfig6" ]]
}

# ── _plasma_ini_write Tests ───────────────────────────────────────────────────

@test "_plasma_ini_write creates new INI file and section" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/plasma_test_XXXXXX)"
  export KDE_CONFIG_DIR="$mock_dir"

  run _plasma_ini_write "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  [ "$status" -eq 0 ]
  [ -f "$mock_dir/kwinrc" ]
  grep -q "\[MouseBindings\]" "$mock_dir/kwinrc"
  grep -q "CommandActiveTitlebar2=Minimize" "$mock_dir/kwinrc"

  rm -rf "$mock_dir"
}

@test "_plasma_ini_write updates existing key in existing group" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/plasma_test_XXXXXX)"
  export KDE_CONFIG_DIR="$mock_dir"

  echo -e "[MouseBindings]\nCommandActiveTitlebar2=Maximize\nOtherKey=Foo" > "$mock_dir/kwinrc"

  run _plasma_ini_write "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  [ "$status" -eq 0 ]
  grep -q "CommandActiveTitlebar2=Minimize" "$mock_dir/kwinrc"
  grep -q "OtherKey=Foo" "$mock_dir/kwinrc"
  # Must not contain old value
  run grep "CommandActiveTitlebar2=Maximize" "$mock_dir/kwinrc"
  [ "$status" -ne 0 ]

  rm -rf "$mock_dir"
}

@test "_plasma_ini_write appends new key to existing group without duplicating" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/plasma_test_XXXXXX)"
  export KDE_CONFIG_DIR="$mock_dir"

  echo -e "[MouseBindings]\nExistingKey=Bar\n" > "$mock_dir/kwinrc"

  run _plasma_ini_write "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  [ "$status" -eq 0 ]
  grep -q "ExistingKey=Bar" "$mock_dir/kwinrc"
  grep -q "CommandActiveTitlebar2=Minimize" "$mock_dir/kwinrc"

  rm -rf "$mock_dir"
}

@test "_plasma_ini_write handles nested KDE groups like services][kitty.desktop" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/plasma_test_XXXXXX)"
  export KDE_CONFIG_DIR="$mock_dir"

  run _plasma_ini_write "kglobalshortcutsrc" "services][kitty.desktop" "_launch" "Ctrl+Alt+T"
  [ "$status" -eq 0 ]
  grep -q "\[services\]\[kitty.desktop\]" "$mock_dir/kglobalshortcutsrc"
  grep -q "_launch=Ctrl+Alt+T" "$mock_dir/kglobalshortcutsrc"

  rm -rf "$mock_dir"
}

# ── plasma_write_config Tests ─────────────────────────────────────────────────

@test "plasma_write_config uses kwriteconfig6 when available" {
  command() {
    if [ "$2" = "kwriteconfig6" ]; then return 0; fi
    builtin command "$@"
  }
  kwriteconfig6() {
    echo "kwriteconfig6 called: $*"
    return 0
  }

  run plasma_write_config "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kwriteconfig6 called: --file kwinrc --group MouseBindings --key CommandActiveTitlebar2 Minimize" ]]
}

@test "plasma_write_config delegates to fallback when kwriteconfig6 is absent" {
  command() {
    if [ "$2" = "kwriteconfig6" ]; then return 1; fi
    builtin command "$@"
  }
  _plasma_ini_write() {
    echo "_plasma_ini_write called: $*"
    return 0
  }

  run plasma_write_config "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "_plasma_ini_write called: kwinrc MouseBindings CommandActiveTitlebar2 Minimize" ]]
}

# ── plasma_apply_colorscheme Tests ────────────────────────────────────────────

@test "plasma_apply_colorscheme invokes CLI tool and updates kdeglobals" {
  command() {
    if [ "$2" = "plasma-apply-colorscheme" ]; then return 0; fi
    builtin command "$@"
  }
  plasma-apply-colorscheme() {
    echo "plasma-apply-colorscheme called with: $*"
  }
  plasma_write_config() {
    echo "plasma_write_config called: $*"
  }

  run plasma_apply_colorscheme "BreezeDark"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "plasma-apply-colorscheme called with: BreezeDark" ]]
  [[ "$output" =~ "plasma_write_config called: kdeglobals KDE LookAndFeelPackage org.kde.breezedark.desktop" ]]
}

# ── configure_plasma_preferences Tests ────────────────────────────────────────

@test "configure_plasma_preferences configures all target groups and keys" {
  ensure_kwriteconfig() { return 0; }
  plasma_apply_colorscheme() {
    echo "colorscheme: $1"
    return 0
  }
  plasma_write_config() {
    echo "config: file=$1 group=$2 key=$3 val=$4"
    return 0
  }

  configure_plasma_panel() {
    echo "configure_plasma_panel called"
    return 0
  }

  run configure_plasma_preferences
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying KDE Plasma 6 window manager preferences..." ]]
  [[ "$output" =~ "config: file=kwinrc group=Desktops key=Number val=4" ]]
  [[ "$output" =~ "config: file=kwinrc group=Desktops key=Rows val=2" ]]
  [[ "$output" =~ "config: file=kwinrc group=MouseBindings key=CommandActiveTitlebar2 val=Minimize" ]]
  [[ "$output" =~ "config: file=kwinrc group=NightColor key=Active val=true" ]]
  [[ "$output" =~ "config: file=kwinrc group=NightColor key=NightTemperature val=4700" ]]
  [[ "$output" =~ "config: file=kwinrc group=TabBox key=LayoutName val=flipswitch" ]]
  [[ "$output" =~ "config: file=kcminputrc group=Mouse key=AccelerationProfile val=flat" ]]
  [[ "$output" =~ "config: file=kcminputrc group=Touchpad key=TwoFingerScroll val=true" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Show Desktop val=Meta+D,Meta+D,Peek at Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][kitty.desktop key=_launch val=Ctrl+Alt+T" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][org.kde.dolphin.desktop key=_launch val=Meta+E" ]]
  [[ "$output" =~ "colorscheme: BreezeDark" ]]
  [[ "$output" =~ "config: file=kdeglobals group=General key=TerminalApplication val=kitty" ]]
  [[ "$output" =~ "config: file=dolphinrc group=General key=RememberOpenedTabs val=false" ]]
  [[ "$output" =~ "configure_plasma_panel called" ]]
}

# ── configure_plasma_panel Tests ──────────────────────────────────────────────

@test "configure_plasma_panel copies template to target config directory" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_panel_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying KDE Plasma 6 panel and taskbar layout..." ]]
  [ -f "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc" ]

  run grep "floating=0" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "AppletOrder=2;3;4;5;6;7;8" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "steam\.desktop,applications:com\.discordapp\.Discord\.desktop" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "lastScreen=0" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "plugin=org.kde.plasma.folder" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  rm -rf "$test_dir"
}

@test "configure_plasma_panel uses D-Bus evaluateScript when plasmashell is active" {
  local script_log
  script_log="$(mktemp /tmp/mock_script_XXXXXX)"

  _get_plasma_dbus_cmd() { echo "mock_qdbus"; }
  mock_qdbus() {
    if [ "$1" = "org.kde.plasmashell" ] && [ "$2" = "/PlasmaShell" ]; then
      if [ -z "${3:-}" ]; then
        return 0
      fi
      if [ "$3" = "org.kde.PlasmaShell.evaluateScript" ]; then
        echo "$4" > "$script_log"
        return 0
      fi
    fi
    return 1
  }

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying KDE Plasma 6 panel layout via Plasma Desktop Scripting (live session)..." ]]
  [[ "$output" =~ "Panel layout script sent to plasmashell successfully." ]]
  [ -s "$script_log" ]

  run grep "org.kde.plasma.kickoff" "$script_log"
  [ "$status" -eq 0 ]

  run grep "org.kde.plasma.icontasks" "$script_log"
  [ "$status" -eq 0 ]

  run grep "showOnlyCurrentDesktop" "$script_log"
  [ "$status" -eq 0 ]

  rm -f "$script_log"
}

@test "configure_plasma_panel does nothing if template is missing" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_panel_missing_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"
  PLASMA_PANEL_TEMPLATE="$test_dir/nonexistent"

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  [[ "$output" != *"Applying KDE Plasma 6 panel and taskbar layout..."* ]]
  [ ! -f "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc" ]

  rm -rf "$test_dir"
}
