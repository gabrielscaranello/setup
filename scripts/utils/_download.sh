#!/bin/bash

# Download, Network, and GitHub Releases Utilities
# Provides curl/wget fallback download abstractions, GitHub release resolution
# with rate-limit resilient HTTP header fallback, version comparisons, and binary installer.

download_file() {
  local url="$1"
  local dest="$2"

  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget > /dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Error: Neither curl nor wget is available to download $url" >&2
    return 1
  fi
}

fetch_url() {
  local url="$1"

  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" 2> /dev/null || true
  elif command -v wget > /dev/null 2>&1; then
    wget -qO- "$url" 2> /dev/null || true
  fi
}

# Returns the latest release tag from a GitHub repository.
# Usage: fetch_github_latest_version <owner/repo>
# Returns: tag name (e.g. "v2.3.1") or empty string on failure
fetch_github_latest_version() {
  local repo="$1"
  local tag=""

  tag="$(fetch_url "https://api.github.com/repos/${repo}/releases/latest" 2> /dev/null \
    | grep '"tag_name"' | head -n 1 | cut -d '"' -f 4 || echo "")"

  if [ -z "$tag" ]; then
    local effective_url=""
    if command -v curl > /dev/null 2>&1; then
      effective_url="$(curl -ILs -o /dev/null -w "%{url_effective}\n" "https://github.com/${repo}/releases/latest" 2> /dev/null || echo "")"
    elif command -v wget > /dev/null 2>&1; then
      effective_url="$(wget --max-redirect=0 "https://github.com/${repo}/releases/latest" 2>&1 | grep -i "Location:" | awk '{print $2}' || echo "")"
    fi
    if [[ "$effective_url" == *"/releases/tag/"* ]]; then
      tag="${effective_url##*/}"
      tag="${tag%$'\r'}"
      tag="${tag%$'\n'}"
    fi
  fi

  echo "$tag"
}

# Returns 0 if local_ver equals remote_ver (and both are non-empty); 1 otherwise.
# Usage: is_version_up_to_date <local_version> <remote_version>
is_version_up_to_date() {
  local local_ver="$1"
  local remote_ver="$2"
  if [ -z "$local_ver" ]; then return 1; fi
  if [ -n "$remote_ver" ] && [ "$local_ver" = "$remote_ver" ]; then return 0; fi
  return 1
}

_download_and_extract_tarball() {
  local name="$1"
  local download_url="$2"
  local output_file="$3"
  local extract_dir="$4"

  echo "Downloading ${name}..."
  download_file "$download_url" "$output_file" || return 1

  echo "Extracting ${name}..."
  mkdir -p "$extract_dir"
  tar -xzf "$output_file" -C "$extract_dir"
}

_install_extracted_binary() {
  local name="$1"
  local src_bin="$2"
  local target_dir="$3"

  echo "Installing ${name} to ${target_dir}..."
  sudo install "$src_bin" "$target_dir/"
}

# Downloads, extracts and installs a single binary from a GitHub Releases tar.gz archive.
#
# Usage:
#   install_github_binary <name> <repo> <version> <file_name> <bin_name>
#
# Arguments:
#   name      — human-readable tool name (e.g. "Lazygit")
#   repo      — GitHub owner/repo slug (e.g. "jesseduffield/lazygit")
#   version   — version string WITHOUT leading "v" (e.g. "0.44.1")
#   file_name — exact archive filename with version and arch already substituted
#               (e.g. "lazygit_0.44.1_Linux_x86_64.tar.gz")
#   bin_name  — name of the binary inside the archive (e.g. "lazygit")
install_github_binary() {
  local name="$1" repo="$2" version="$3" file_name="$4" bin_name="$5"
  local clean_version="${version#v}"
  local download_url work_dir output_file extract_dir
  local target_dir="/usr/local/bin"

  download_url="https://github.com/${repo}/releases/download/v${clean_version}/${file_name}"

  install_packages curl wget tar || true

  echo "Installing ${name} (${version})..."
  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/${name}-install.XXXXXX")"
  output_file="${work_dir}/${file_name}"
  extract_dir="${work_dir}/extract"

  if ! _download_and_extract_tarball "$name" "$download_url" "$output_file" "$extract_dir" \
    || ! _install_extracted_binary "$name" "$extract_dir/$bin_name" "$target_dir"; then
    rm -rf "$work_dir"
    return 1
  fi

  echo "Cleaning up temporary files..."
  rm -rf "$work_dir"

  echo "${name} installed successfully at $(command -v "$bin_name" || echo "${target_dir}/${bin_name}")"
}
