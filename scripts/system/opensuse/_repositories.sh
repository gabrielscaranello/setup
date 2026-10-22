#!/bin/bash

# openSUSE-specific repository helper functions (sourced as utility, not executed directly)
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || source "scripts/_utils.sh" 2> /dev/null || true

get_opensuse_version() {
  if [ "$(get_distro_id 2> /dev/null || true)" = "opensuse-tumbleweed" ]; then
    echo "tumbleweed"
    return 0
  fi

  local version_id
  version_id="$(get_os_release_field VERSION_ID)"
  if [ -n "$version_id" ]; then
    echo "$version_id"
    return 0
  fi

  echo "16.0"
}

add_opensuse_packman_repo() {
  if [ -f /etc/zypp/repos.d/packman-essentials.repo ] || zypper lr packman-essentials > /dev/null 2>&1; then
    echo "Packman repository already configured on openSUSE, skipping."
    return 0
  fi

  local version
  version="$(get_opensuse_version)"
  local repo_url
  if [ "$version" = "tumbleweed" ]; then
    repo_url="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"
  else
    repo_url="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_${version}/Essentials/"
  fi

  echo "Configuring Packman Essentials repository for openSUSE (${version})..."
  sudo zypper --non-interactive addrepo -cfp 90 "$repo_url" packman-essentials 2> /dev/null || true
  sudo zypper --non-interactive --gpg-auto-import-keys refresh packman-essentials 2> /dev/null || true
}

add_opensuse_nonfree_repo() {
  echo "Ensuring openSUSE Non-OSS repository is enabled..."
  if zypper lr "openSUSE:repo-non-oss" > /dev/null 2>&1; then
    sudo zypper --non-interactive mr -e "openSUSE:repo-non-oss" 2> /dev/null || true
  elif zypper lr repo-non-oss > /dev/null 2>&1; then
    sudo zypper --non-interactive mr -e repo-non-oss 2> /dev/null || true
  fi
}

add_opensuse_vscodium_repo() {
  local repo_file="/etc/zypp/repos.d/vscodium.repo"
  if [ -f "$repo_file" ] || zypper lr vscodium > /dev/null 2>&1; then
    echo "VSCodium repository already configured on openSUSE, skipping."
    return 0
  fi

  echo "Configuring VSCodium repository for Zypper..."
  sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg 2> /dev/null || true
  sudo zypper --non-interactive addrepo -cfp 90 https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/ vscodium 2> /dev/null || true
  sudo zypper --non-interactive --gpg-auto-import-keys refresh vscodium 2> /dev/null || true
}

add_opensuse_nvidia_repo() {
  local version
  version="$(get_opensuse_version)"

  if [ "$version" = "tumbleweed" ]; then
    echo "openSUSE Tumbleweed uses native upstream kernel graphics drivers, skipping extra NVIDIA repo."
    return 0
  fi

  if zypper lr NVIDIA > /dev/null 2>&1 || zypper lr repo-non-free > /dev/null 2>&1 || zypper ls NVIDIA > /dev/null 2>&1; then
    echo "NVIDIA repository already configured on openSUSE, skipping."
    return 0
  fi

  echo "Configuring NVIDIA repository for openSUSE Leap (${version})..."
  if zypper se -t package openSUSE-repos-Leap-NVIDIA > /dev/null 2>&1; then
    install_packages openSUSE-repos-Leap-NVIDIA || true
  else
    sudo zypper --non-interactive addrepo --refresh "https://download.nvidia.com/opensuse/leap/${version}" NVIDIA 2> /dev/null || true
  fi

  sudo zypper --non-interactive --gpg-auto-import-keys refresh 2> /dev/null || true
}

add_opensuse_mozilla_repo() {
  local repo_file="/etc/zypp/repos.d/mozilla.repo"
  if [ -f "$repo_file" ] || zypper lr mozilla > /dev/null 2>&1; then
    echo "Mozilla repository already configured on openSUSE, skipping."
    return 0
  fi

  local version
  version="$(get_opensuse_version)"

  local repo_url
  if [ "$version" = "tumbleweed" ]; then
    repo_url="https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed/mozilla.repo"
  else
    repo_url="https://download.opensuse.org/repositories/mozilla/16.0/mozilla.repo"
  fi

  echo "Configuring Mozilla repository for openSUSE (${version})..."
  sudo zypper --non-interactive addrepo -cfp 90 "$repo_url" 2> /dev/null || true
  sudo zypper --non-interactive --gpg-auto-import-keys refresh mozilla 2> /dev/null || true
}

add_opensuse_kernel_backports_repo() {
  local repo_name="Kernel:stable"
  if [ -f "/etc/zypp/repos.d/${repo_name}.repo" ] || [ -f "/etc/zypp/repos.d/Kernel_stable.repo" ] || zypper lr "$repo_name" > /dev/null 2>&1 || zypper lr "Kernel_stable" > /dev/null 2>&1 || zypper lr "Kernel_stable_Backport" > /dev/null 2>&1; then
    echo "Kernel stable repository already configured on openSUSE, skipping."
    return 0
  fi

  local version
  version="$(get_opensuse_version)"

  if [ "$version" = "tumbleweed" ]; then
    echo "openSUSE Tumbleweed already runs the latest rolling kernel. Skipping kernel repository."
    return 0
  fi

  local repo_url="https://download.opensuse.org/repositories/Kernel:/stable/standard"

  echo "Configuring Kernel stable repository for openSUSE Leap (${version})..."
  sudo zypper --non-interactive addrepo -cfp 90 "$repo_url" "$repo_name" 2> /dev/null || true
  sudo zypper --non-interactive --gpg-auto-import-keys refresh "$repo_name" 2> /dev/null || true
}
