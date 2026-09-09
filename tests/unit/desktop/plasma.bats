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

@test "plasma_write_config splits nested groups for kwriteconfig6" {
  command() {
    if [ "$2" = "kwriteconfig6" ]; then return 0; fi
    builtin command "$@"
  }
  kwriteconfig6() {
    echo "kwriteconfig6 called: $*"
    return 0
  }

  run plasma_write_config "kglobalshortcutsrc" "services][kitty.desktop" "_launch" "Ctrl+Alt+T"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kwriteconfig6 called: --file kglobalshortcutsrc --group services --group kitty.desktop --key _launch Ctrl+Alt+T" ]]
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

# ── _configure_plasma_desktops_dbus Tests ─────────────────────────────────────

@test "_configure_plasma_desktops_dbus sets 4 desktops and 2 rows via D-Bus when KWin is active" {
  local dbus_calls
  dbus_calls="$(mktemp /tmp/mock_kwin_dbus_XXXXXX)"

  _get_plasma_dbus_cmd() { echo "mock_qdbus"; }
  mock_qdbus() {
    echo "$*" >> "$dbus_calls"
    if [ "$1" = "org.kde.KWin" ] && [ "$2" = "/KWin" ]; then
      return 0
    fi
    if [ "$1" = "org.kde.KWin" ] && [ "$2" = "/VirtualDesktopManager" ]; then
      if [ "$3" = "count" ] || [ "$3" = "org.kde.KWin.VirtualDesktopManager.count" ]; then
        echo "2"
        return 0
      fi
      return 0
    fi
    return 0
  }

  run _configure_plasma_desktops_dbus
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring KDE Plasma 6 virtual desktops via KWin D-Bus..." ]]
  [ -s "$dbus_calls" ]

  run grep "createDesktop 3 Desktop 3" "$dbus_calls"
  [ "$status" -eq 0 ]

  run grep "createDesktop 4 Desktop 4" "$dbus_calls"
  [ "$status" -eq 0 ]

  run grep "rows 2" "$dbus_calls"
  [ "$status" -eq 0 ]

  run grep "reconfigure" "$dbus_calls"
  [ "$status" -eq 0 ]

  rm -f "$dbus_calls"
}

@test "_configure_plasma_desktops_dbus gracefully skips when KWin is absent" {
  _get_plasma_dbus_cmd() { echo "mock_qdbus"; }
  mock_qdbus() { return 1; }

  run _configure_plasma_desktops_dbus
  [ "$status" -eq 0 ]
  [[ "$output" != *"Configuring KDE Plasma 6 virtual desktops via KWin D-Bus..."* ]]
}

# ── _reload_plasma_shortcuts_dbus Tests ───────────────────────────────────────

@test "_reload_plasma_shortcuts_dbus triggers kbuildsycoca and reloads KWin and kglobalaccel via D-Bus" {
  local calls_file
  calls_file="$(mktemp /tmp/mock_reload_dbus_XXXXXX)"

  command() {
    if [ "$2" = "kbuildsycoca6" ]; then return 0; fi
    builtin command "$@"
  }
  kbuildsycoca6() {
    echo "kbuildsycoca6 called: $*" >> "$calls_file"
    return 0
  }
  _get_plasma_dbus_cmd() { echo "mock_qdbus"; }
  mock_qdbus() {
    echo "mock_qdbus called: $*" >> "$calls_file"
    return 0
  }

  run _reload_plasma_shortcuts_dbus
  [ "$status" -eq 0 ]
  [ -s "$calls_file" ]

  run grep "kbuildsycoca6 called: --noincremental" "$calls_file"
  [ "$status" -eq 0 ]

  run grep "mock_qdbus called: org.kde.KWin /KWin" "$calls_file"
  [ "$status" -eq 0 ]

  run grep "mock_qdbus called: org.kde.kglobalaccel /kglobalaccel" "$calls_file"
  [ "$status" -eq 0 ]

  rm -f "$calls_file"
}

@test "_reload_plasma_shortcuts_dbus gracefully skips when D-Bus is unavailable" {
  command() {
    if [ "$2" = "kbuildsycoca6" ]; then return 1; fi
    if [ "$2" = "kbuildsycoca5" ]; then return 1; fi
    builtin command "$@"
  }
  _get_plasma_dbus_cmd() { return 1; }

  run _reload_plasma_shortcuts_dbus
  [ "$status" -eq 0 ]
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
  _clear_plasma_kickoff_favorites() {
    echo "_clear_plasma_kickoff_favorites called"
    return 0
  }
  _configure_plasma_desktops_dbus() {
    echo "_configure_plasma_desktops_dbus called"
    return 0
  }
  _reload_plasma_shortcuts_dbus() {
    echo "_reload_plasma_shortcuts_dbus called"
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
  [[ "$output" =~ "config: file=kwinrc group=Desktops key=Name_1 val=Desktop 1" ]]
  [[ "$output" =~ "config: file=kwinrc group=MouseBindings key=CommandActiveTitlebar2 val=Minimize" ]]
  [[ "$output" =~ "config: file=kwinrc group=NightColor key=Active val=true" ]]
  [[ "$output" =~ "config: file=kwinrc group=NightColor key=NightTemperature val=4700" ]]
  [[ "$output" =~ "config: file=kwinrc group=TabBox key=LayoutName val=flipswitch" ]]
  [[ "$output" =~ "config: file=kwinrc group=org.kde.kdecoration2 key=ButtonsOnLeft val=E" ]]
  [[ "$output" =~ "config: file=kwinrc group=org.kde.kdecoration2 key=ButtonsOnRight val=IAX" ]]
  [[ "$output" =~ "config: file=kcminputrc group=Mouse key=AccelerationProfile val=flat" ]]
  [[ "$output" =~ "config: file=kcminputrc group=Touchpad key=TwoFingerScroll val=true" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Show Desktop val=Meta+D,Meta+D,Peek at Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Window Maximize val=Meta+M,Meta+PgUp,Maximize Window" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Window Minimize val=none,Meta+PgDown,Minimize Window" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Switch to Next Desktop val=Meta+PgDown,,Switch to Next Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Switch to Previous Desktop val=Meta+PgUp,,Switch to Previous Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Window to Next Desktop val=Meta+Shift+PgDown,,Window to Next Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=kwin key=Window to Previous Desktop val=Meta+Shift+PgUp,,Window to Previous Desktop" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][kitty.desktop key=_launch val=Ctrl+Alt+T" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][org.kde.dolphin.desktop key=_launch val=Meta+E" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][org.kde.krunner.desktop key=_launch val=Meta+Space"$'\t'"Search"$'\t'"Alt+Space"$'\t'"Alt+F2" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=services][org.kde.plasma-systemmonitor.desktop key=_launch val=Meta+Esc"$'\t'"Ctrl+Shift+Esc" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=plasmashell key=show-on-mouse-pos val=Meta+V"$'\t'"Meta+Shift+V,Meta+V,Show Clipboard Items at Mouse Position" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=plasmashell key=next activity val=Meta+A,none,Walk Through Activities" ]]
  [[ "$output" =~ "config: file=kglobalshortcutsrc group=plasmashell key=previous activity val=Meta+Shift+A,none,Walk Through Activities (Reverse)" ]]
  [[ "$output" =~ "colorscheme: BreezeDark" ]]
  [[ "$output" =~ "config: file=kdeglobals group=General key=TerminalApplication val=kitty" ]]
  [[ "$output" =~ "config: file=kdeglobals group=General key=fixed val=JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" ]]
  [[ "$output" =~ "config: file=ksmserverrc group=General key=loginMode val=emptySession" ]]
  [[ "$output" =~ "config: file=dolphinrc group=General key=RememberOpenedTabs val=false" ]]
  [[ "$output" =~ "config: file=dolphinrc group=General key=HomeUrl val=file://$HOME" ]]
  [[ "$output" =~ "config: file=krunnerrc group=General key=FreeFloating val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_powerdevilEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_servicesEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_systemsettingsEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=helprunnerEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=calculatorEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_appstreamEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=unitconverterEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_colorsEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_killEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=windowsEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_kwinEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_shellEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_placesrunnerEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=locationsEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_plasma-desktopEnabled val=true" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=baloosearchEnabled val=false" ]]
  [[ "$output" =~ "config: file=krunnerrc group=Plugins key=krunner_bookmarksrunnerEnabled val=false" ]]
  [[ "$output" =~ "config: file=plasmaparc group=General key=AudioFeedback val=false" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/Trash: emptied key=Action val=" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/beep key=Action val=" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/catastrophe key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/deviceAdded key=Action val=" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/deviceRemoved key=Action val=" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/fatalerror key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/messageCritical key=Action val=Taskbar" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/messageInformation key=Action val=Taskbar" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/messageQuestion key=Action val=Taskbar" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/messageWarning key=Action val=Taskbar" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/notification key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/printerror key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=plasma_workspace.notifyrc group=Event/warning key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=oom-notifier.notifyrc group=Event/catastrophe key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=plasma_applet_timer.notifyrc group=Event/timerFinished key=Action val=Popup|Sound" ]]
  [[ "$output" =~ "config: file=plasma_applet_timer.notifyrc group=Event/timerFinished key=Sound val=alarm-clock-elapsed" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/pluggedin key=Action val=" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/unplugged key=Action val=" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/fullbattery key=Action val=" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/lowperipheralbattery key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/lowbattery key=Action val=Sound|Popup" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/lowbattery key=Sound val=battery-caution" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/criticalbattery key=Action val=Sound|Popup" ]]
  [[ "$output" =~ "config: file=powerdevil.notifyrc group=Event/criticalbattery key=Sound val=battery-low" ]]
  [[ "$output" =~ "config: file=polkit-kde-authentication-agent-1.notifyrc group=Event/authenticate key=Action val=" ]]
  [[ "$output" =~ "config: file=kwrited.notifyrc group=Event/NewMessage key=Action val=Popup" ]]
  [[ "$output" =~ "config: file=kactivitymanagerd-pluginsrc group=Plugin-org.kde.ActivityManager.Resources.Scoring key=what-to-remember val=2" ]]
  [[ "$output" =~ "config: file=kactivitymanagerdrc group=Plugins key=org.kde.ActivityManager.ResourceScoringEnabled val=false" ]]
  [[ "$output" =~ "config: file=krunnerrc group=General key=historyBehavior val=Disabled" ]]
  [[ "$output" =~ "config: file=baloofilerc group=Basic Settings key=Indexing-Enabled val=false" ]]
  [[ "$output" =~ "config: file=plasmashellrc group=PlasmaViews][Panel 1][Defaults key=thickness val=40" ]]
  [[ "$output" =~ "_clear_plasma_kickoff_favorites called" ]]
  [[ "$output" =~ "_configure_plasma_desktops_dbus called" ]]
  [[ "$output" =~ "_reload_plasma_shortcuts_dbus called" ]]
  [[ "$output" =~ "configure_plasma_panel called" ]]
}

# ── _clear_plasma_kickoff_favorites Tests ─────────────────────────────────────

@test "_clear_plasma_kickoff_favorites creates empty stats file when missing" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_fav_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"

  run _clear_plasma_kickoff_favorites
  [ "$status" -eq 0 ]
  [ -f "$test_dir/config/kactivitymanagerd-statsrc" ]
  run grep "ordering=" "$test_dir/config/kactivitymanagerd-statsrc"
  [ "$status" -eq 0 ]

  rm -rf "$test_dir"
}

@test "_clear_plasma_kickoff_favorites clears existing ordering in stats file" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_fav_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"
  mkdir -p "$KDE_CONFIG_DIR"

  cat << 'EOF' > "$KDE_CONFIG_DIR/kactivitymanagerd-statsrc"
[Favorites-org.kde.plasma.kickoff.favorites.instance-2-global]
ordering=applications:firefox.desktop,applications:org.kde.dolphin.desktop
EOF

  run _clear_plasma_kickoff_favorites
  [ "$status" -eq 0 ]
  run grep -E "ordering=\s*$" "$test_dir/config/kactivitymanagerd-statsrc"
  [ "$status" -eq 0 ]
  run grep "applications:firefox.desktop" "$test_dir/config/kactivitymanagerd-statsrc"
  [ "$status" -ne 0 ]

  rm -rf "$test_dir"
}

@test "_clear_plasma_kickoff_favorites deletes favorites from activity database" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_fav_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"
  XDG_DATA_HOME="$test_dir/data"
  local db_dir="$XDG_DATA_HOME/kactivitymanagerd/resources"
  mkdir -p "$db_dir"

  python3 -c '
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("CREATE TABLE ResourceLink (initiatingAgent TEXT, targettedResource TEXT);")
cur.execute("INSERT INTO ResourceLink VALUES (\"org.kde.plasma.favorites.applications\", \"applications:firefox.desktop\");")
conn.commit()
conn.close()
' "$db_dir/database"

  run _clear_plasma_kickoff_favorites
  [ "$status" -eq 0 ]

  run python3 -c '
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM ResourceLink;")
count = cur.fetchone()[0]
conn.close()
sys.exit(0 if count == 0 else 1)
' "$db_dir/database"
  [ "$status" -eq 0 ]

  rm -rf "$test_dir"
}

@test "_clear_plasma_kickoff_favorites overrides default favorites in kicker-extra-favoritesrc" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_fav_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"

  run _clear_plasma_kickoff_favorites
  [ "$status" -eq 0 ]
  [ -f "$test_dir/config/kicker-extra-favoritesrc" ]
  run grep "IgnoreDefaults\[\$i\]=true" "$test_dir/config/kicker-extra-favoritesrc"
  [ "$status" -eq 0 ]
  run grep "Prepend\[\$i\]=" "$test_dir/config/kicker-extra-favoritesrc"
  [ "$status" -eq 0 ]

  rm -rf "$test_dir"
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

  run grep "thickness=40" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "displayedText=None" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "AppletOrder=2;3;4;5;6;7;8" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "applications:org\.kde\.dolphin\.desktop" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "steam\.desktop,applications:com\.discordapp\.Discord\.desktop" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "lastScreen=0" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
  [ "$status" -eq 0 ]

  run grep "favoritesPortedToStats=true" "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc"
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

  run grep "panel.height = 40" "$script_log"
  [ "$status" -eq 0 ]

  run grep "org.kde.plasma.kickoff" "$script_log"
  [ "$status" -eq 0 ]

  run grep "favoritesPortedToStats" "$script_log"
  [ "$status" -eq 0 ]

  run grep "org.kde.plasma.icontasks" "$script_log"
  [ "$status" -eq 0 ]

  run grep "applications:org.kde.dolphin.desktop" "$script_log"
  [ "$status" -eq 0 ]

  run grep "showOnlyCurrentDesktop" "$script_log"
  [ "$status" -eq 0 ]

  run grep 'displayedText.*None' "$script_log"
  [ "$status" -eq 0 ]

  run grep "allWidgets" "$script_log"
  [ "$status" -eq 0 ]

  run grep "start-here.svg" "$script_log"
  [ "$status" -eq 0 ]

  rm -f "$script_log"
}

@test "configure_plasma_panel deploys template and configures start-here icon" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_panel_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"
  _get_plasma_dbus_cmd() { return 1; }

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  [ -f "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc" ]

  local content
  content="$(cat "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc")"
  [[ "$content" =~ "icon=" ]]
  [[ "$content" =~ "start-here.svg" ]]
  [[ ! "$content" =~ ":start-here-icon:" ]]

  rm -rf "$test_dir"
}

@test "_setup_plasma_start_icon installs arch icon on Arch Linux" {
  local test_home
  test_home="$(mktemp -d /tmp/plasma_icon_test_XXXXXX)"
  HOME="$test_home"
  get_distro_id() { echo "arch"; }

  run _setup_plasma_start_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing KDE Plasma start menu icon for arch..." ]]
  [ -f "$test_home/.icons/start-here.svg" ]
  [ -f "$test_home/.local/share/icons/start-here.svg" ]

  rm -rf "$test_home"
}

@test "_setup_plasma_start_icon installs debian icon on Debian" {
  local test_home
  test_home="$(mktemp -d /tmp/plasma_icon_test_XXXXXX)"
  HOME="$test_home"
  get_distro_id() { echo "debian"; }

  run _setup_plasma_start_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing KDE Plasma start menu icon for debian..." ]]
  [ -f "$test_home/.icons/start-here.svg" ]
  [ -f "$test_home/.local/share/icons/start-here.svg" ]

  rm -rf "$test_home"
}

@test "_setup_plasma_start_icon installs fedora icon on Fedora" {
  local test_home
  test_home="$(mktemp -d /tmp/plasma_icon_test_XXXXXX)"
  HOME="$test_home"
  get_distro_id() { echo "fedora"; }

  run _setup_plasma_start_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing KDE Plasma start menu icon for fedora..." ]]
  [ -f "$test_home/.icons/start-here.svg" ]
  [ -f "$test_home/.local/share/icons/start-here.svg" ]

  rm -rf "$test_home"
}

@test "_setup_plasma_start_icon does not install icon when distribution is unknown" {
  local test_home
  test_home="$(mktemp -d /tmp/plasma_icon_test_XXXXXX)"
  HOME="$test_home"
  get_distro_id() { echo "unknown"; }

  run _setup_plasma_start_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Distribution 'unknown' is not recognized for start menu icon. Leaving default icon." ]]
  [ ! -f "$test_home/.icons/start-here.svg" ]
  [ ! -f "$test_home/.local/share/icons/start-here.svg" ]

  rm -rf "$test_home"
}

@test "configure_plasma_panel removes icon setting when icon file is absent" {
  local test_dir
  test_dir="$(mktemp -d /tmp/plasma_panel_test_XXXXXX)"
  KDE_CONFIG_DIR="$test_dir/config"
  KDE_START_HERE_ICON="$test_dir/nonexistent.svg"
  _get_plasma_dbus_cmd() { return 1; }

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  [ -f "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc" ]

  local content
  content="$(cat "$test_dir/config/plasma-org.kde.plasma.desktop-appletsrc")"
  [[ ! "$content" =~ "icon=" ]]
  [[ ! "$content" =~ ":start-here-icon:" ]]
  [[ "$content" =~ "showSeconds=onlyInTooltip" ]]

  rm -rf "$test_dir"
}

@test "configure_plasma_panel with D-Bus omits icon when icon file is absent" {
  local script_log
  script_log="$(mktemp /tmp/mock_script_XXXXXX)"
  KDE_START_HERE_ICON="/nonexistent/start-here.svg"

  _get_plasma_dbus_cmd() { echo "mock_qdbus"; }
  mock_qdbus() {
    if [ "$1" = "org.kde.plasmashell" ] && [ "$2" = "/PlasmaShell" ]; then
      if [ -z "${3:-}" ]; then return 0; fi
      if [ "$3" = "org.kde.PlasmaShell.evaluateScript" ]; then
        echo "$4" > "$script_log"
        return 0
      fi
    fi
    return 1
  }

  run configure_plasma_panel
  [ "$status" -eq 0 ]
  run grep "writeConfig(\"icon\"" "$script_log"
  [ "$status" -ne 0 ]
  run grep "writeConfig(\"showSeconds\", \"onlyInTooltip\")" "$script_log"
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
