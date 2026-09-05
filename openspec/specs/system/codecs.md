# Setup System Codecs

## Overview

Install multimedia codecs and audio/video plugins across all supported distributions (Debian, Fedora, Arch Linux). This ensures robust multimedia playback capabilities including support for various audio/video formats and streaming protocols.

## Requirements

### Supported Distributions

- **Debian 13 (Trixie)**
- **Fedora 44**
- **Arch Linux**

### Packages to Install

- **Debian**: `ffmpeg`, `gstreamer1.0-plugins-base`, `gstreamer1.0-plugins-good`, `gstreamer1.0-plugins-bad`, `gstreamer1.0-plugins-ugly`, `gstreamer1.0-libav`, `libavcodec-extra`
- **Fedora**: `ffmpeg`, `gstreamer1-plugins-base`, `gstreamer1-plugins-good`, `gstreamer1-plugins-bad-free`, `gstreamer1-plugins-bad-freeworld`, `gstreamer1-plugins-ugly`, `gstreamer1-libav`, `gstreamer1-plugin-openh264`
- **Arch Linux**: `ffmpeg`, `gst-plugins-base`, `gst-plugins-good`, `gst-plugins-bad`, `gst-plugins-ugly`, `gst-libav`

### Configuration Requirements

- **Fedora**: Must configure and enable RPM Fusion repositories (Free and Non-Free) before installing packages to ensure access to full codec implementations. Uses existing `add_fedora_rpmfusion_repo` helper.
- **Debian**: Uses default repositories. No third-party repo required.
- **Arch Linux**: Uses default repositories. No third-party repo required.

## Test Scenarios

### Feature: Codecs Installation

**Scenario: Install codecs on Debian**

- **GIVEN** the system is Debian
- **WHEN** the codecs setup script is executed
- **THEN** it should install the Debian-specific codec packages via `install_packages`

**Scenario: Install codecs on Fedora**

- **GIVEN** the system is Fedora
- **WHEN** the codecs setup script is executed
- **THEN** it should add RPM Fusion repositories
- **AND** install the Fedora-specific codec packages via `install_packages`

**Scenario: Install codecs on Arch Linux**

- **GIVEN** the system is Arch Linux
- **WHEN** the codecs setup script is executed
- **THEN** it should install the Arch-specific codec packages via `install_packages`

**Scenario: Unsupported distribution**

- **GIVEN** the system is an unsupported distribution
- **WHEN** the codecs setup script is executed
- **THEN** it should gracefully skip or fail fast depending on convention
