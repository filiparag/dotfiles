#!/bin/sh

output=""

for p in $(playerctl -l 2>/dev/null); do
	if [ $(playerctl -p $p status) = 'Playing' ] || [ $(playerctl -p $p status) = 'Paused' ]; then
		track="$(
			playerctl -p $p metadata | awk -v status="$(playerctl -p $p status)" \
			'BEGIN {
				artist=""
				title=""
			}
			/xesam:artist/ {
				if (NF>=3)
					for (i=3;i<=NF;i++)
						artist = artist sprintf("%s ",$i);
			}
			/xesam:title/ {
				if (NF>=3)
					for (i=3;i<=NF;i++)
						title = title sprintf("%s ",$i);
			}
			END {
				if (status == "Playing")
					printf("󰎇 ")
			else if (status == "Paused")
					printf("󰎊 ")
				if(length(artist) > 0)
					printf("%s", artist)
				if(length(artist) > 0 && length(title) > 0)
					printf("– ")
				if(length(title) > 0)
					printf("%s", title)
				printf("\n")

			}'
		)"
		output="$(
			printf "%s\n%s" "$output" "$track" | sed '/^$/d'
		)"
	fi
done

printf "%s" "$output" | LC_ALL=C sort -k1.1 | head -n 1 | cut -c 1-64