#! /bin/bash

QUERY=$(rofi -dmenu -theme Arc-Dark -p "Google" -width 27 -lines 0)

if [[ $QUERY = *[!\ ]* ]]; then
  QUERY=$(echo $QUERY | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g')
  firefox -new-tab "https://google.com/search?q=$QUERY"
  echo $QUERY
else
  echo "\$param consists of spaces only"
fi
