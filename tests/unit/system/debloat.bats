#!/usr/bin/env bats
# shellcheck disable=SC2218,SC2030,SC2031,SC2317

# Unit tests for setup-debloat.sh logic and distro/DE branches

setup() {
  source /setup/scripts/system/setup-debloat.sh
}

@test "_filter_installed_debian filters packages matching dpkg install status" {
  dpkg() {
    if [ "$2" = "installed-pkg" ]; then
      echo "Status: install ok installed"
      return 0
    fi
    return 1
  }

  run _filter_installed_debian "installed-pkg" "missing-pkg"
  [ "$status" -eq 0 ]
  [ "$output" = "installed-pkg" ]
}

@test "_filter_installed_fedora filters packages matching rpm -q" {
  rpm() {
    if [ "$2" = "installed-pkg" ]; then
      return 0
    fi
    return 1
  }

  run _filter_installed_fedora "installed-pkg" "missing-pkg"
  [ "$status" -eq 0 ]
  [ "$output" = "installed-pkg" ]
}

@test "_debloat_debian skips when DEBLOAT_SKIP_PACKAGE_REMOVAL is set" {
  get_desktop_environment() { echo "gnome"; }
  DEBLOAT_SKIP_PACKAGE_REMOVAL=1 run _debloat_debian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "DEBLOAT_SKIP_PACKAGE_REMOVAL is active" ]]
}

@test "_debloat_debian purges packages on GNOME when installed" {
  get_desktop_environment() { echo "gnome"; }
  _filter_installed_debian() {
    echo "totem libreoffice-core gimp"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _debloat_debian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Purging unused Debian packages: totem libreoffice-core gimp" ]]
  [[ "$output" =~ "sudo apt purge -y totem libreoffice-core gimp" ]]
  [[ "$output" =~ "sudo apt autoremove --purge -y" ]]
}

@test "_debloat_debian purges packages on KDE Plasma when installed" {
  get_desktop_environment() { echo "plasma"; }
  _filter_installed_debian() {
    echo "dragonplayer juk konsole"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _debloat_debian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Purging unused Debian packages: dragonplayer juk konsole" ]]
  [[ "$output" =~ "sudo apt purge -y dragonplayer juk konsole" ]]
}

@test "_debloat_debian handles no installed packages gracefully" {
  get_desktop_environment() { echo "gnome"; }
  _filter_installed_debian() {
    echo ""
  }

  run _debloat_debian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No unused Debian packages found to remove." ]]
}

@test "_debloat_fedora skips when DEBLOAT_SKIP_PACKAGE_REMOVAL is set" {
  get_desktop_environment() { echo "gnome"; }
  DEBLOAT_SKIP_PACKAGE_REMOVAL=1 run _debloat_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "DEBLOAT_SKIP_PACKAGE_REMOVAL is active" ]]
}

@test "_debloat_fedora removes packages on GNOME when installed" {
  get_desktop_environment() { echo "gnome"; }
  _filter_installed_fedora() {
    echo "totem decibels mediawriter"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _debloat_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Removing unused Fedora packages: totem decibels mediawriter" ]]
  [[ "$output" =~ "sudo dnf remove -y totem decibels mediawriter" ]]
  [[ "$output" =~ "sudo dnf autoremove -y" ]]
}

@test "_debloat_fedora removes packages on KDE Plasma when installed" {
  get_desktop_environment() { echo "plasma"; }
  _filter_installed_fedora() {
    echo "dragon juk konsole kmail kontact"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _debloat_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Removing unused Fedora packages: dragon juk konsole kmail kontact" ]]
  [[ "$output" =~ "sudo dnf remove -y dragon juk konsole kmail kontact" ]]
}

@test "_debloat_fedora handles no installed packages gracefully" {
  get_desktop_environment() { echo "gnome"; }
  _filter_installed_fedora() {
    echo ""
  }

  run _debloat_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No unused Fedora packages found to remove." ]]
}

@test "main delegates to _debloat_debian on debian" {
  get_distro_id() { echo "debian"; }
  _debloat_debian() { echo "called debloat debian"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called debloat debian" ]]
  [[ "$output" =~ "setup-debloat complete" ]]
}

@test "main delegates to _debloat_fedora on fedora" {
  get_distro_id() { echo "fedora"; }
  _debloat_fedora() { echo "called debloat fedora"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called debloat fedora" ]]
  [[ "$output" =~ "setup-debloat complete" ]]
}

@test "main cleanly bypasses debloat on arch" {
  get_distro_id() { echo "arch"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Arch Linux is minimal by default; debloat is not needed." ]]
  [[ "$output" =~ "setup-debloat complete" ]]
}

@test "main fails on unsupported distribution" {
  get_distro_id() { echo "unknown_distro"; }

  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution for debloat: unknown_distro" ]]
}
