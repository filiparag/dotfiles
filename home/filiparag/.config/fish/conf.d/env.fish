# Configuration environment variables

# Qt 5
set -x QT_QPA_PLATFORMTHEME "qt5ct"
set -x QT_AUTO_SCREEN_SCALE_FACTOR 0

# Fzf
set -x FZF_LEGACY_KEYBINDINGS 0

# Go
set -x GOPATH   $HOME/Projects/go
set -x PATH     "$PATH:$GOPATH/bin"

# Local binaries
set -x PATH     "$PATH:$HOME/.local/bin"

# JetBrains IDE
set -x _JAVA_AWT_WM_NONREPARENTING 1
set -x _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'