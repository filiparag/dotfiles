#! /bin/bash

# for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
for monitor in $(xrandr --listmonitors | egrep -Eo "+: (\*|\+)+[a-zA-Z0-9-]+" | egrep -o "[a-zA-Z0-9-]+"); do
	bspc monitor $monitor -d {1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}
done