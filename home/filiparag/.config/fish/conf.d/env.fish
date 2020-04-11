# Configuration environment variables

# Qt 5
set -g -x QT_QPA_PLATFORMTHEME "qt5ct"
set -g -x QT_AUTO_SCREEN_SCALE_FACTOR 0

# Fzf
set -g -x FZF_LEGACY_KEYBINDINGS 0

# Go
set -g -x GOPATH   $HOME/Projects/go
set -g -x PATH     "$PATH:$GOPATH/bin"

# Local binaries
set -g -x PATH     "$PATH:$HOME/.local/bin"

# JetBrains IDE
set -g -x _JAVA_AWT_WM_NONREPARENTING 1
set -g -x _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'

# Sxhkd
set -g -x SXHKD_SHELL '/usr/bin/dash'