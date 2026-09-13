#!/bin/bash

# KDE Plasma 6 Kickoff and Activity Manager Favorites Cleanup
# Clears pinned and default application favorites from kactivitymanagerd stats,
# SQLite activity database, and kicker/kickoff system configuration overrides.

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || true

_clear_plasma_kickoff_favorites() {
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local stats_file="${config_dir}/kactivitymanagerd-statsrc"
  local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
  local db_file="${data_dir}/kactivitymanagerd/resources/database"

  # Stop kactivitymanagerd if active in live session so changes are not overwritten
  local restart_kactivity=0
  if command -v systemctl > /dev/null 2>&1 && systemctl --user is-active plasma-kactivitymanagerd.service > /dev/null 2>&1; then
    systemctl --user stop plasma-kactivitymanagerd.service 2> /dev/null || true
    restart_kactivity=1
  fi

  mkdir -p "$config_dir"
  if [ ! -f "$stats_file" ]; then
    touch "$stats_file"
  fi

  awk '
    BEGIN {
      in_favorites = 0
      printed_any = 0
    }
    /^\[.*\]$/ {
      if ($0 ~ /Favorites/) {
        in_favorites = 1
        seen[$0] = 1
      } else {
        in_favorites = 0
      }
    }
    {
      if (in_favorites && $0 ~ /^ordering=/) {
        print "ordering="
        next
      }
      print
      printed_any = 1
    }
    function add_section(sec) {
      if (!seen[sec]) {
        if (printed_any) {
          print ""
        }
        print sec
        print "ordering="
        seen[sec] = 1
        printed_any = 1
      }
    }
    END {
      for (i = 1; i <= 30; i++) {
        add_section("[Favorites-org.kde.plasma.kickoff.favorites.instance-" i "-global]")
        add_section("[Favorites-org.kde.plasma.kicker.favorites.instance-" i "-global]")
      }
      add_section("[Favorites-org.kde.plasma.favorites.applications]")
    }
  ' "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"

  if [ -f "$db_file" ] && command -v sqlite3 > /dev/null 2>&1; then
    sqlite3 "$db_file" "DELETE FROM ResourceLink WHERE initiatingAgent LIKE '%favorites%' OR initiatingAgent LIKE '%kickoff%' OR initiatingAgent LIKE '%kicker%' OR targettedResource LIKE 'applications:%';" 2> /dev/null || true
  fi

  if [ "$restart_kactivity" -eq 1 ]; then
    systemctl --user start plasma-kactivitymanagerd.service 2> /dev/null || true
  fi

  # Override distribution/system default favorites (e.g. Fedora kde-settings kicker-extra-favoritesrc)
  # Prepend[$i]= and IgnoreDefaults[$i]=true ensure KDE does not re-seed default favorites on new session login
  local kicker_extra_fav="${config_dir}/kicker-extra-favoritesrc"
  cat << 'EOF' > "$kicker_extra_fav"
[General]
Prepend=
Prepend[$i]=
Append=
Append[$i]=
Favorites=
Favorites[$i]=
IgnoreDefaults=true
IgnoreDefaults[$i]=true
EOF

  local kickoff_rc="${config_dir}/kickoffrc"
  cat << 'EOF' > "$kickoff_rc"
[General]
favorites=
favorites[$i]=
EOF

  if sudo -n true 2> /dev/null; then
    sudo mkdir -p /etc/xdg
    sudo tee /etc/xdg/kicker-extra-favoritesrc > /dev/null << 'EOF' || true
[General]
Prepend=
Append=
IgnoreDefaults=true
EOF
  fi
}
