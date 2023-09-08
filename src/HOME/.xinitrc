#!/bin/sh

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

dbus-update-activation-environment --systemd DISPLAY
eval "$(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
export SSH_AUTH_SOCK

export XDG_SESSION_TYPE=x11

! command -v wmrc >/dev/null && \
    >&2 echo "wmrc not found in PATH!" && exit 1

deps="$(wmrc check-deps)"
if [ -n "$deps" ]; then
    >&2 echo "$deps"
    exit 1
fi

exec wmrc start "wm/$(wmrc var WM)"
