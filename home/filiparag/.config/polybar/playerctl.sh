#!/bin/sh

output=""

for p in $(playerctl -l 2>/dev/null); do
	status="$(playerctl -p "$p" status)"
	if [ "$status" = 'Playing' ] || [ "$status" = 'Paused' ]; then
		artist="$(
			playerctl -p "$p" metadata -f '{{ xesam:artist }}' 
		)"
		title="$(
			playerctl -p "$p" metadata -f '{{ xesam:title }}' | \
			sed 's/([0-9]*) *//; s/ - YouTube$//'
		)"
		case "$(playerctl -p "$p" status)" in
			Playing)
				status_icon='󰝚';;
			Paused)
				status_icon='󰏤';;
		esac
		output="$(
			printf "%s\n%s %s%s" "$output" "$status_icon" "${artist:+$artist – }" "$title" | sed '/^$/d'
		)"
	fi
done

printf "%s" "$output" | LC_ALL=C sort -r -k1.1 | head -n 1 | cut -c 1-64