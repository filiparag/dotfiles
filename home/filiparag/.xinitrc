#! /usr/bin/env dash

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

export SXHKD_SHELL='/bin/dash'

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

! command -v wmrc >/dev/null && \
    >&2 echo "wmrc not found in PATH!" && exit 1

DEPS="$(wmrc -m | tr '\n' ' ')"

[ -n "$DEPS" ] && \
    >&2 echo "wmrc has missing dependencies:\n$DEPS" && exit 1

WM="$(wmrc -v | perl -n -e'/^WM=(.+)/ && print $1')"

exec "$WM"
