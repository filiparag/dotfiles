#! /bin/bash

setxkbmap -layout "us,rs,rs" -variant ",latinunicode," -option grp:alt_shift_toggle

if [[ `cat /sys/devices/virtual/dmi/id/product_family` =~ "ThinkPad" ]]; then

	xmodmap -e "keycode 112 = Home"
	xmodmap -e "keycode 117 = End"
	xmodmap -e "keycode 107 = Menu"
	xmodmap -e "keycode 110 = Prior"
	xmodmap -e "keycode 115 = Next"

fi