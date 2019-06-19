#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RESOLUTION=`xrandr | grep \* |awk ' NR==1 {print $1}'`

SCALEDDIR=$DIR/.scaled

ORIGINAL=$DIR/image.*

rm -rf $ORIGINAL $DIR/.color $SCALEDDIR

COLOR=$(hexdump -n 3 -v -e '3/1 "%02X" "\n"' /dev/random)

convert -size $RESOLUTION xc:#$COLOR $DIR/image.png

echo $COLOR > $DIR/.color