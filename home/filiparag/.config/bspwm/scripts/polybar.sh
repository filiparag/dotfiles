#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

WLP=$(ip -o link show | awk -F': ' '{print $2}' | grep wlp)
ENP=$(ip -o link show | awk -F': ' '{print $2}' | grep enp)

# Launch bar1 and bar2
# polybar main &

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m WLP=$WLP ENP=$ENP polybar --reload main &
  done
else
  polybar --reload main &
fi