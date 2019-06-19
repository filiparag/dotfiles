#! /bin/bash

scrot -s '%Y-%m-%d-%H-%M-%S.png' -e 'mv $f /home/filiparag/Pictures/Screenshots/; xclip -selection clipboard -t image/png /home/filiparag/Pictures/Screenshots/%Y-%m-%d-%H-%M-%S.png'