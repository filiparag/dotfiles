# Configuration environment variables

# XDG
set -g -x XDG_CONFIG_HOME "$HOME/.config"
set -g -x XDG_CACHE_HOME "$HOME/.cache"
set -g -x XDG_DATA_HOME "$HOME/.local/share"
set -g -x XDG_STATE_HOME "$HOME/.local/state"

# Qt 5
set -g -x QT_QPA_PLATFORMTHEME qt5ct
set -g -x QT_AUTO_SCREEN_SCALE_FACTOR 0

# Fzf
set -g -x FZF_LEGACY_KEYBINDINGS 0

# Local binaries
set -g -x PATH "$PATH:$HOME/.local/bin"

# JetBrains IDE
set -g -x _JAVA_AWT_WM_NONREPARENTING 1
set -g -x _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'

# Sxhkd
set -g -x SXHKD_SHELL /usr/bin/dash

# Locale
set -g -x LC_ALL 'en_US.UTF-8'
set -g -x LANGUAGE 'en_US.UTF-8'
set -g -x LANG 'en_US.UTF-8'

# Cargo
set -g -x CARGO_TARGET_DIR "$HOME/.cargo/target"

# Valgrind
set -x DEBUGINFOD_URLS 'https://debuginfod.archlinux.org'

# Firefox
set -x MOZ_USE_XINPUT2 1

