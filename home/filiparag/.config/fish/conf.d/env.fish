# Configuration environment variables

# Qt 5
set -U QT_QPA_PLATFORMTHEME "qt5ct"
set -U QT_AUTO_SCREEN_SCALE_FACTOR 0

# Fzf
set -U FZF_LEGACY_KEYBINDINGS 0

# Go
set -U GOPATH   $HOME/Projects/go
set -U PATH     "$PATH:$GOPATH/bin"

# Local binaries
set -U PATH     "$PATH:$HOME/.local/bin"

# JetBrains IDE
set -x _JAVA_AWT_WM_NONREPARENTING 1
set -x _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'