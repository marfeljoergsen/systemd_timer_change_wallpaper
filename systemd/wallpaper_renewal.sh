#!/usr/bin/env bash

# Black background color:
# i3lock -c 000000 -n
# ---
# i3lock -t -i lockscreen.png
# below: -n
# i3lock -i fake-desktop.png -p default -n

# ----
# Autochange background, put this into a file:
# while true ; do feh --bg-max  -z *.jpg; sleep 2; done
# --
# Or maybe try, from commandline:
# watch -n 1200 feh --randomize --bg-fill ~/Pictures/* &>/dev/null &

#srcDir=("/home/mfj/Desktop/wallPaperAccess_com/"{Antenna,NASA})
srcDir=("/home/martin/Desktop/wallPapers_nice/")
randomFile=$(find "${srcDir[@]}" -type f -iname "*.jpg" | shuf -n 1)
cmdPrefix="feh --randomize --bg-max"
echo "$cmdPrefix $randomFile"
$($cmdPrefix "$randomFile")

