#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# DISPLAY=$DISPLAY feh --bg-scale `$DIR/current.py`
DISPLAY=$DISPLAY feh --bg-tile $DIR/images/dark.png

# CRONJOB="*/10 * * * * DISPLAY=$DISPLAY $DIR/set.sh"

# CRON=/var/spool/cron/$USER

# sudo su root -c "grep '$DIR/set.sh' $CRON || echo '$CRONJOB' >> $CRON"