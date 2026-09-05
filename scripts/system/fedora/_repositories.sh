#!/bin/bash

# Fedora-specific repository helper functions (sourced as utility, not executed directly)

add_fedora_docker_repo() {
  local repo_file="/etc/yum.repos.d/docker-ce.repo"
  if [ -f "$repo_file" ]; then
    echo "Docker CE repository already configured on Fedora, skipping."
    return 0
  fi

  echo "Configuring Docker CE repository for Fedora..."
  sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
}

add_fedora_vscodium_repo() {
  local repo_path="/etc/yum.repos.d/vscodium.repo"

  if [ -f "$repo_path" ]; then
    echo "VSCodium repository already configured on Fedora, skipping."
    return 0
  fi

  echo "Configuring VSCodium repository for DNF..."
  cat << 'EOF_REPO' | sudo tee "$repo_path" > /dev/null
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
EOF_REPO
}

add_fedora_rpmfusion_repo() {
  local free_repo="/etc/yum.repos.d/rpmfusion-free.repo"
  local nonfree_repo="/etc/yum.repos.d/rpmfusion-nonfree.repo"

  if [ -f "$free_repo" ] && [ -f "$nonfree_repo" ]; then
    echo "RPM Fusion repositories already configured on Fedora, skipping."
    return 0
  fi

  echo "Configuring RPM Fusion repositories for Fedora..."
  local fedora_version
  fedora_version="$(rpm -E %fedora 2> /dev/null || echo "rawhide")"
  sudo dnf install -y --nogpgcheck \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm" 2> /dev/null || true
}
