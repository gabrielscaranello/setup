#!/bin/bash

# Declarative Debloat Package Catalogs
# Sourced by scripts/system/setup-debloat.sh. Do NOT execute directly.

COMMON_DEBLOAT_PACKAGES=(
  libreoffice-core
  xterm
  kate
  brasero
  deja-dup
  transmission-common
)

COMMON_GNOME_DEBLOAT_PACKAGES=(
  totem
  gnome-music
  rhythmbox
  cheese
  snapshot
  gnome-photos
  shotwell
  gnome-terminal
  ptyxis
  evolution
  gnome-boxes
  gnome-characters
  gnome-connections
  gnome-maps
  gnome-sound-recorder
  gnome-tour
  simple-scan
  gedit
  remmina
  polari
)

COMMON_PLASMA_DEBLOAT_PACKAGES=(
  juk
  konsole
  konqueror
  akregator
  kdepim
  kdepim-runtime
  kmail
  kontact
  korganizer
  konversation
  kamera
  kcalc
  kfind
  kmag
  kmousetool
  kmouth
  kontrast
  kuiviewer
  kwalletmanager
  sweeper
  skanlite
)

COMMON_CINNAMON_DEBLOAT_PACKAGES=(
  celluloid
  hypnotix
  mintchat
  rhythmbox
  simple-scan
  sticky
  thingy
  thunderbird
)

OPEN_SUSE_COMMON_DEBLOAT_PACKAGES=(
  libreoffice
  transmission
  opensuse-welcome
  opensuse-welcome-launcher
  patterns-desktop-multimedia
  patterns-office-office
  vim
  lftp
)

OPEN_SUSE_GNOME_DEBLOAT_PACKAGES=(
  dconf-editor
  gnome-console
  gnome-packagekit
  patterns-gnome-gnome_games
  patterns-gnome-gnome_multimedia
  patterns-gnome-gnome_office
  patterns-gnome-gnome_utilities
  system-config-printer
  vinagre
)

OPEN_SUSE_PLASMA_DEBLOAT_PACKAGES=(
  feh
  icewm
  patterns-kde-kde_games
  patterns-kde-kde_multimedia
  patterns-kde-kde_office
  patterns-kde-kde_pim
  patterns-kde-kde_utilities
)
