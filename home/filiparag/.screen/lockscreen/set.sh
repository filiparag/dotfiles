#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RESOLUTION=`xrandr | grep \* |awk ' NR==1 {print $1}'`

SCALEDDIR=$DIR/.scaled

mkdir -p $SCALEDDIR

# RANDFILE=$(ls $DIR/images | shuf -n 1)
# FILENAME=$(basename $RANDFILE .png)

# find source image with any extension
# ORIGINAL=$DIR/image.*

# ORIGINAL=$DIR/images/$RANDFILE

ORIGINAL=$DIR/images/arch.png

SCALED=$SCALEDDIR/$FILENAME.$RESOLUTION.png

# COLOR=$(cat $DIR/.color)
COLOR="043663"

if [ -f $SCALED ]; then
   # scaled version exists already
   :
else
   # notify-send Lockscreen "Applying new lockscreen image" -u low;
   i3lock -c $COLOR -u &
   convert $ORIGINAL -resize $RESOLUTION $SCALED
   # convert $ORIGINAL -resize 1x1 $DIR/.color.txt
   # cat $DIR/.color.txt | gawk 'match($0, "#[0-9a-fA-F]{6}") {print substr($0, RSTART + 1, RLENGTH)}' > $DIR/.color
   # rm $DIR/.color.txt
   pkill i3lock
fi

# PASSW=$(cat $DIR/.password)

i3lock -i $SCALED -c $COLOR -u


