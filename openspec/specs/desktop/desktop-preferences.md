# Configure Desktop Environment Preferences

## Overview

Automate desktop environment preferences and system application configurations across supported distributions (**Debian 13**, **Fedora 44**, and **Arch Linux**).

Supports both primary desktop environments:

- **GNOME**: Configured via modular `dconf` dumps organized under `config/gnome/` applied idempotently via `_dconf.sh`.
- **KDE Plasma 6** (Plasma 6.3 on Debian 13, Plasma 6.7 on Arch Linux and Fedora 44): Configured via granular CLI tools (`kwriteconfig6`, `plasma-apply-colorscheme`) and direct INI configuration merging under `~/.config/` applied idempotently via `_plasma.sh`.

## Requirements

### Desktop Environment Support & Skip Policy

- **Environment Detection**:
  - The script checks the current desktop environment using `get_desktop_environment`.
  - **GNOME**: When `get_desktop_environment` returns `gnome`, the script delegates to GNOME configuration routines.
  - **KDE Plasma**: When `get_desktop_environment` returns `plasma`, the script delegates to KDE Plasma 6 configuration routines.
- **Unsupported DE Skip Invariant**:
  - Whenever `get_desktop_environment` returns an unsupported or unknown environment (such as `xfce`, `cinnamon`, or `unknown`), the script **MUST IMMEDIATELY SKIP** all configuration steps.
  - It outputs an informative log message and **exits with return code 0** without modifying any configuration settings or files.

### 1. GNOME Desktop Environment Preferences

#### Prerequisites

- `dconf` command-line utility available (`dconf load`, `dconf write`).
- Automatic dependency resolution via `install_packages dconf`.
- Headless / container execution wrapper: automatically executes with `dbus-run-session` when `DBUS_SESSION_BUS_ADDRESS` is empty.

#### Modular Configuration Files (`config/gnome/*.dconf`)

1. **Interface & Appearance** (`interface.dconf`):
   - Clock: seconds and weekday display enabled (`clock-show-seconds=true`, `clock-show-weekday=true`).
   - Typography: JetBrainsMono Nerd Font 11 (monospace); system default UI font preserved.
   - Mouse: primary clipboard paste on middle-click disabled (`gtk-enable-primary-paste=false`).
   - Timezone: automatic timezone detection enabled (`automatic-timezone=true`).
   - Sounds: event sounds disabled (`event-sounds=false`), theme `freedesktop`.
2. **Peripherals** (`peripherals.dconf`):
   - Mouse: flat acceleration profile (`accel-profile='flat'`).
   - Touchpad: two-finger scrolling enabled (`two-finger-scrolling-enabled=true`).
3. **Window Manager & Keybindings** (`window-manager.dconf`):
   - Titlebar middle click: minimizes window.
   - Global shortcuts: Show Desktop (`<Super>d`), Home Folder (`<Super>e`), Terminal (`<Control><Alt>t` -> `kitty`), Flameshot (`<Control><Alt>s` -> `flameshot gui`).
4. **Night Light** (`night-light.dconf`):
   - Enabled with manual continuous schedule (from 4.0 to ~3.98), temperature 4700K.
5. **Privacy & Search Providers** (`privacy.dconf`):
   - Recent files retention 30 days, `remember-recent-files=false`, auto-clean old temp/trash files.
   - Search providers: disable Clocks, Seahorse, Contacts, Nautilus.
6. **Nautilus File Manager** (`nautilus.dconf`):
   - Default zoom `small-plus`, tree view navigation enabled in list view.
7. **Shell & App Folders** (`shell.dconf`):
   - Dash favorite apps: Dynamically resolved based on distribution and installed desktop entries: Nautilus, Kitty, VS Code/Codium (`code-oss.desktop` on Arch, `codium.desktop` on Debian/Fedora), Firefox (`org.mozilla.firefox.desktop` on Fedora, `firefox.desktop` on Arch/Debian), Chromium (`chromium-browser.desktop` on Fedora, `chromium.desktop` on Arch, `org.chromium.Chromium.desktop` on Debian), DBeaver, OnlyOffice, Obsidian (`obsidian.desktop` on Arch, `md.obsidian.Obsidian.desktop` on Debian/Fedora), GIMP (`gimp.desktop` on Arch/Fedora, `org.gimp.GIMP.desktop` on Debian), Telegram, Steam, Discord (`discord.desktop` on Arch, `com.discordapp.Discord.desktop` on Debian/Fedora).
   - App picker folders: Games (`ProtonPlus`, `MangoJuice`, `Steam`), Develop (`DBeaver`, `Compass`), System, Utilities (including `VLC`).
8. **Applications** (`apps.dconf`):
   - GNOME Text Editor: highlight current line, space indentation, dark style scheme.
   - System Monitor: custom CPU core colors, resources tab default, user processes filter.

#### GNOME Workspace Startup Environment Script for NVM

- Sourced from template `config/gnome/env/nvm.sh` and deployed to `~/.config/gnome/env/nvm.sh`.
- XDG autostart desktop entry deployed from `config/gnome/autostart/nvm-env.desktop` to `~/.config/autostart/nvm-env.desktop`.
- Systemd user environment generator deployed to `~/.config/systemd/user-environment-generators/10-nvm.sh` to inject `NVM_DIR`, `NVM_BIN`, and Node `PATH` early in the session lifecycle for GNOME Shell and all child processes.
- Idempotent: safe to run multiple times without duplicating or overwriting user configurations.

---

### 2. KDE Plasma 6 Desktop Environment Preferences (Approach 2: Granular CLI)

#### Compatibility & Target Platforms

- **Debian 13 (Trixie)**: KDE Plasma 6.3
- **Fedora 44**: KDE Plasma 6.7
- **Arch Linux**: KDE Plasma 6.7

#### Prerequisites & Tooling

- Primary CLI utility: `kwriteconfig6` (provided by `kconfig` on Arch, `kf6-kconfig` on Fedora, and `libkf6config-bin` on Debian 13).
- Theme application utility: `plasma-apply-colorscheme` (provided by `plasma-workspace`).
- Fallback mechanism: In minimal container or headless test environments without `kwriteconfig6`, the configuration routines must safely write or update INI key/value pairs directly in the corresponding `~/.config/<filename>` files.

#### Granular Configuration Specifications

1. **Window Management & Visual Effects (`~/.config/kwinrc`)**:
   - **Virtual Desktops (2x2 Grid)**:
     - Group: `[Desktops]`
     - Keys: `Number=4`, `Rows=2`
   - **Titlebar Middle Click**:
     - Group: `[MouseBindings]`
     - Key: `CommandActiveTitlebar2=Minimize`
   - **Night Color (Luz Noturna)**:
     - Group: `[NightColor]`
     - Keys: `Active=true`, `Mode=Constant`, `NightTemperature=4700`
   - **Alt-Tab Task Switcher (Interruptor Flip / Flipswitch)**:
     - Group: `[TabBox]`
     - Key: `LayoutName=flipswitch`
   - **Titlebar Buttons (Botões na Barra de Título)**:
     - Group: `[org.kde.kdecoration2]`
     - Keys: `ButtonsOnLeft=E` (Ocultar de captura e gravação de tela / `hide-from-screencast`), `ButtonsOnRight=IAX` (Minimizar, Maximizar, Fechar)
   - **Window Effects**:
   - Group: `[Plugins]`
   - Keys: `blurEnabled=true`, `magiclampEnabled=true`

2. **Peripherals & Mouse Acceleration (`~/.config/kcminputrc`)**:
   - **Mouse Acceleration Profile**:
     - Group: `[Mouse]`
     - Key: `AccelerationProfile=flat`
   - **Touchpad Scrolling**:
     - Group: `[Touchpad]`
     - Key: `TwoFingerScroll=true`

3. **Global Keyboard Shortcuts (`~/.config/kglobalshortcutsrc`)**:
   - **Show Desktop**:
     - Group: `[kwin]`
     - Key: `Show Desktop=Meta+D,Meta+D,Peek at Desktop`
   - **Window Maximize**:
     - Group: `[kwin]`
     - Key: `Window Maximize=Meta+M,Meta+PgUp,Maximize Window`
   - **Window Minimize** (cleared to avoid conflict with desktop navigation):
     - Group: `[kwin]`
     - Key: `Window Minimize=none,Meta+PgDown,Minimize Window`
   - **Switch to Next / Previous Desktop**:
     - Group: `[kwin]`
     - Keys: `Switch to Next Desktop=Meta+PgDown,,Switch to Next Desktop`, `Switch to Previous Desktop=Meta+PgUp,,Switch to Previous Desktop`
   - **Window to Next / Previous Desktop**:
     - Group: `[kwin]`
     - Keys: `Window to Next Desktop=Meta+Shift+PgDown,,Window to Next Desktop`, `Window to Previous Desktop=Meta+Shift+PgUp,,Window to Previous Desktop`
   - **Terminal Emulator (Kitty)**:
     - Group: `[services][kitty.desktop]`
     - Key: `_launch=Ctrl+Alt+T`
   - **File Manager (Dolphin)**:
     - Group: `[services][org.kde.dolphin.desktop]`
     - Key: `_launch=Meta+E`
   - **Application Runner (KRunner)**:
     - Group: `[services][org.kde.krunner.desktop]`
     - Key: `_launch=Meta+Space\tSearch\tAlt+Space\tAlt+F2` (tab-separated)
   - **System Monitor (Plasma System Monitor)**:
     - Group: `[services][org.kde.plasma-systemmonitor.desktop]`
     - Key: `_launch=Meta+Esc\tCtrl+Shift+Esc` (tab-separated)
   - **Clipboard History on Mouse Position**:
     - Group: `[plasmashell]`
     - Key: `show-on-mouse-pos=Meta+V\tMeta+Shift+V,Meta+V,Show Clipboard Items at Mouse Position` (tab-separated)
   - **Activities Navigation**:
     - Group: `[plasmashell]`
     - Keys: `next activity=Meta+A,none,Walk Through Activities`, `previous activity=Meta+Shift+A,none,Walk Through Activities (Reverse)`

4. **Appearance, Fonts & System Defaults (`~/.config/kdeglobals`)**:
   - **Color Scheme**:
     - Apply `BreezeDark` via `plasma-apply-colorscheme BreezeDark` or set:
     - Group: `[KDE]`
     - Key: `LookAndFeelPackage=org.kde.breezedark.desktop`
   - **Typography**:
     - Group: `[General]`
     - `fixed=JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1`
   - **Default Terminal Application**:
     - Group: `[General]`
     - Keys: `TerminalApplication=kitty`, `TerminalService=kitty.desktop`

5. **Dolphin File Manager (`~/.config/dolphinrc`)**:
   - Group: `[General]`
   - Keys: `RememberOpenedTabs=false`, `HomeUrl=file://${HOME}`

6. **Session Management (`~/.config/ksmserverrc`)**:
   - **Start with Empty Session**:
     - Group: `[General]`
     - Key: `loginMode=emptySession`

7. **KRunner Application Launcher (`~/.config/krunnerrc`)**:
   - **Center Screen Floating Position**:
     - Group: `[General]`
     - Key: `FreeFloating=true`
   - **Plasma Search Runners (`[Plugins]`)**:
     - Enabled Runners (`true`):
       - `krunner_powerdevilEnabled=true` (Energia)
       - `krunner_servicesEnabled=true` (Aplicativos)
       - `krunner_systemsettingsEnabled=true` (Configurações do sistema)
       - `helprunnerEnabled=true` (Ajuda do executor)
       - `calculatorEnabled=true` (Calculadora)
       - `krunner_appstreamEnabled=true` (Central de aplicativos)
       - `unitconverterEnabled=true` (Conversor de unidades)
       - `krunner_colorsEnabled=true` (Cores)
       - `krunner_killEnabled=true` (Encerrar aplicativos)
       - `windowsEnabled=true` (Janelas)
       - `krunner_kwinEnabled=true` (KWin)
       - `krunner_shellEnabled=true` (Linha de comando)
       - `krunner_placesrunnerEnabled=true` (Locais)
       - `locationsEnabled=true` (Localizações)
       - `krunner_plasma-desktopEnabled=true` (Shell da área de trabalho Plasma)
     - Disabled Runners (`false`):
       - `baloosearchEnabled=false` (Pesquisa de arquivos)
       - `browserhistoryEnabled=false` (Histórico do navegador)
       - `browsertabsEnabled=false` (Abas do navegador)
       - `krunner_bookmarksrunnerEnabled=false` (Favoritos)
       - `krunner_charrunnerEnabled=false` (Caracteres especiais)
       - `org.kde.datetimeEnabled=false` (Data e hora)
       - `krunner_dictionaryEnabled=false` (Dicionário)
       - `krunner_katesessionsEnabled=false` (Sessões do Kate)
       - `krunner_keysEnabled=false` (Atalhos globais)
       - `krunner_konsoleprofilesEnabled=false` (Perfis do Konsole)
       - `krunner_recentdocumentsEnabled=false` (Arquivos recentes)
       - `krunner_sessionsEnabled=false` (Sessões da área de trabalho)
       - `krunner_spellcheckEnabled=false` (Verificador ortográfico)
       - `krunner_webshortcutsEnabled=false` (Palavras-chave de pesquisa na Web)
       - `org.kde.activities2Enabled=false` (Atividades)

8. **Audio Volume Feedback (`~/.config/plasmaparc`)**:
   - **Disable Volume Change Beep/Feedback**:
     - Group: `[General]`
     - Key: `AudioFeedback=false`

9. **Application Notification Sounds (`~/.config/plasma_workspace.notifyrc`, `~/.config/oom-notifier.notifyrc`, `~/.config/plasma_applet_timer.notifyrc`, `~/.config/powerdevil.notifyrc`, `~/.config/polkit-kde-authentication-agent-1.notifyrc`, `~/.config/kwrited.notifyrc`)**:
   - **Disable Sound for Plasma Workspace Events**:
     - Group: `[Event/Trash: emptied]`, Key: `Action=`
     - Group: `[Event/beep]`, Key: `Action=`
     - Group: `[Event/catastrophe]`, Key: `Action=Popup`
     - Group: `[Event/deviceAdded]`, Key: `Action=`
     - Group: `[Event/deviceRemoved]`, Key: `Action=`
     - Group: `[Event/fatalerror]`, Key: `Action=Popup`
     - Group: `[Event/messageCritical]`, Key: `Action=Taskbar`
     - Group: `[Event/messageInformation]`, Key: `Action=Taskbar`
     - Group: `[Event/messageQuestion]`, Key: `Action=Taskbar`
     - Group: `[Event/messageWarning]`, Key: `Action=Taskbar`
     - Group: `[Event/notification]`, Key: `Action=Popup`
     - Group: `[Event/printerror]`, Key: `Action=Popup`
     - Group: `[Event/warning]`, Key: `Action=Popup`
     - Group: `[Event/startkde]`, Keys: `Action=`, `Sound=`
     - Group: `[Event/exitkde]`, Keys: `Action=`, `Sound=`
     - Group: `[Event/cancellogout]`, Keys: `Action=`, `Sound=`
     - Group: `[Event/login]`, Keys: `Action=`, `Sound=`
     - Group: `[Event/logout]`, Keys: `Action=`, `Sound=`
   - **Disable Screen Locker Sounds (`kscreenlocker.notifyrc`)**:
     - Group: `[Event/locked]`, Keys: `Action=`, `Sound=`
     - Group: `[Event/unlocked]`, Keys: `Action=`, `Sound=`
   - **OOM Notifier**:
     - Group: `[Event/catastrophe]`, Key: `Action=Popup`
   - **Keep Timer Sound Enabled**:
     - File: `plasma_applet_timer.notifyrc`
     - Group: `[Event/timerFinished]`, Keys: `Action=Popup|Sound`, `Sound=alarm-clock-elapsed`
   - **Power Management Sounds (`powerdevil.notifyrc`)**:
     - Group: `[Event/pluggedin]`, Key: `Action=`
     - Group: `[Event/unplugged]`, Key: `Action=`
     - Group: `[Event/fullbattery]`, Key: `Action=`
     - Group: `[Event/lowperipheralbattery]`, Key: `Action=Popup`
     - Group: `[Event/lowbattery]`, Keys: `Action=Sound|Popup`, `Sound=battery-caution`
     - Group: `[Event/criticalbattery]`, Keys: `Action=Sound|Popup`, `Sound=battery-low`
   - **Authentication System Sounds (`polkit-kde-authentication-agent-1.notifyrc`)**:
     - Group: `[Event/authenticate]`, Key: `Action=`
   - **Local System Message Service Sounds (`kwrited.notifyrc`)**:
     - Group: `[Event/NewMessage]`, Key: `Action=Popup`

10. **Recent Files & Activity Privacy (`~/.config/kactivitymanagerd-pluginsrc`, `~/.config/kactivitymanagerdrc`, `~/.config/krunnerrc`)**:
    - **Do Not Remember Opened Documents**:
      - File: `kactivitymanagerd-pluginsrc`, Group: `[Plugin-org.kde.ActivityManager.Resources.Scoring]`, Key: `what-to-remember=2`
    - **Disable Resource Scoring Plugin**:
      - File: `kactivitymanagerdrc`, Group: `[Plugins]`, Key: `org.kde.ActivityManager.ResourceScoringEnabled=false`
    - **Disable KRunner History**:
      - File: `krunnerrc`, Group: `[General]`, Key: `historyBehavior=Disabled`

11. **File Indexing & Baloo Search (`~/.config/baloofilerc`)**:
    - **Disable File Indexing**:
      - File: `baloofilerc`, Group: `[Basic Settings]`, Key: `Indexing-Enabled=false`
      - Run `balooctl6 disable` / `balooctl disable` when available to immediately stop any running indexing daemon.

12. **Panel & Taskbar Layout**:

- **Panel Height & Style**: Configured to 40px height (`panel.height = 40;` in D-Bus script, `thickness=40` in `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc`) and docked non-floating (`floating=0` / `panel.floating = false;` across all panel views in `plasmashellrc` and containments in `plasma-org.kde.plasma.desktop-appletsrc`).
- **Live Session (D-Bus)**: When `plasmashell` and `kwin` are active, invokes `evaluateScript` via `qdbus6`/`qdbus` to safely build and configure the bottom panel without altering desktop containments, enforces `panel.floating = false;` and `writeConfig("floating", 0)`, configures KWin virtual desktops (4 desktops, 2 rows) via `org.kde.KWin.VirtualDesktopManager`, and forces KWin reconfigure.
- **Offline Fallback (`~/.config/plasma-org.kde.plasma.desktop-appletsrc`)**: Deploys a complete corona template containing screen mapping, desktop containment (`org.kde.plasma.folder`, `lastScreen=0`), and the bottom panel (`location=4`, `floating=0`, `thickness=40`, `formfactor=2`, `lastScreen=0`).
- Ordered applets (`AppletOrder=2;3;4;5;6;7;8`):
  1.  Application Launcher (`org.kde.plasma.kickoff`) — custom start menu icon (Papirus distributor-logo `start-here.svg` installed to `~/.icons/start-here.svg` per distro: Arch Linux, Debian, Fedora), compact session/power buttons without captions/labels (`showActionButtonCaptions=false`), favorites section cleared / empty (`favorites=""`, `favoritesPortedToStats=true`, `icon=~/.icons/start-here.svg`, and immutable override in `kicker-extra-favoritesrc` with `IgnoreDefaults[$i]=true` and `Prepend[$i]=` to prevent distribution defaults from returning upon session restart)
  2.  Separator (`org.kde.plasma.marginsseparator`)
  3.  Icons-Only Task Manager (`org.kde.plasma.icontasks`) — pinned launchers: Dolphin, Kitty, VS Code/Codium (`code-oss.desktop` on Arch, `codium.desktop` on Debian/Fedora), Firefox (`org.mozilla.firefox.desktop` on Fedora, `firefox.desktop` on Arch/Debian), Chromium (`chromium-browser.desktop` on Fedora, `chromium.desktop` on Arch, `org.chromium.Chromium.desktop` on Debian), DBeaver, OnlyOffice, Obsidian (`obsidian.desktop` on Arch, `md.obsidian.Obsidian.desktop` on Debian/Fedora), GIMP (`gimp.desktop` on Arch/Fedora, `org.gimp.GIMP.desktop` on Debian), Telegram, Steam, Discord (`discord.desktop` on Arch, `com.discordapp.Discord.desktop` on Debian/Fedora); shows open apps across all virtual desktops (`showOnlyCurrentDesktop=false`)
  4.  Pager (`org.kde.plasma.pager`) — virtual desktops (2 rows, text display disabled / `displayedText=None`)
  5.  Separator (`org.kde.plasma.marginsseparator`)
  6.  System Tray (`org.kde.plasma.systemtray`)
  7.  Digital Clock (`org.kde.plasma.digitalclock`) — short date, date display enabled, seconds displayed only in tooltip (`showSeconds="onlyInTooltip"`)

13. **Workspace Environment Startup Scripts (`~/.config/plasma-workspace/env/`)**:
    - **NVM Environment (`nvm.sh`)**: Deploys `~/.config/plasma-workspace/env/nvm.sh` with executable permissions (`+x`) from template `config/plasma/plasma-workspace/env/nvm.sh` to initialize NVM (`export NVM_DIR="$HOME/.nvm"`, source `nvm.sh`, `bash_completion`, and `/usr/share/nvm/init-nvm.sh`) on login in KDE Plasma sessions.

---

### Idempotency & Execution Mechanics

- Running the script repeatedly produces identical configuration values across all targeted keys without duplicates or errors.
- Any existing non-conflicting user settings in other groups within the `.config` files are preserved.

## Test Scenarios

### Feature: Desktop Environment Preferences

**Scenario: Unsupported Desktop Environment**

- **GIVEN** `get_desktop_environment` returns `unknown` or `xfce`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should output an informative skip message
- **AND** exit with return code 0 without modifying any configuration

**Scenario: GNOME Desktop Environment Preferences Application**

- **GIVEN** `get_desktop_environment` returns `gnome`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should ensure `dconf` is available
- **AND** load all 8 `.dconf` files from `config/gnome/`
- **AND** exit with return code 0

**Scenario: KDE Plasma 6 Desktop Environment Preferences Application**

- **GIVEN** `get_desktop_environment` returns `plasma`
- **WHEN** `setup-desktop-preferences.sh` is executed
- **THEN** it should configure virtual desktops to a 2x2 grid (Number=4, Rows=2) in kwinrc
- **AND** configure KWin titlebar middle click to Minimize
- **AND** configure Night Color to constant 4700K
- **AND** configure Alt-Tab task switcher layout to flipswitch
- **AND** configure titlebar buttons to ButtonsOnLeft=E and ButtonsOnRight=IAX in kwinrc
- **AND** configure mouse acceleration profile to flat in kcminputrc
- **AND** configure global shortcuts (Meta+D, Meta+M, Window Minimize=none, Meta+PgDown/PgUp, Meta+Shift+PgDown/PgUp, Ctrl+Alt+T, Meta+E, Meta+Space, Meta+Esc/Ctrl+Shift+Esc, Meta+V/Meta+Shift+V, Meta+A/Meta+Shift+A) in kglobalshortcutsrc
- **AND** configure default terminal to Kitty and monospace font in kdeglobals
- **AND** configure session to start with an empty session in ksmserverrc
- **AND** configure Dolphin to open at home directory without remembering tabs in dolphinrc
- **AND** configure KRunner to float centrally in krunnerrc
- **AND** disable audio volume feedback in plasmaparc
- **AND** silence notification sounds for Plasma apps while preserving timer sound and low/critical battery sounds in notifyrc files
- **AND** disable remembering recent files in kactivitymanagerd-pluginsrc, kactivitymanagerdrc, and krunnerrc
- **AND** disable file indexing in baloofilerc
- **AND** exit with return code 0

**Scenario: Idempotent Execution on KDE Plasma 6**

- **GIVEN** KDE Plasma 6 preferences are already applied
- **WHEN** `setup-desktop-preferences.sh` is executed again
- **THEN** all configurations should remain intact
- **AND** exit with return code 0
