#!/usr/bin/env bash

# =======================================================================
# This script currently works by randomly selecting a "landscape"-format
# wallpaper for my leftmost monitor, a "portrait"-format wallpaper for
# the middle monitor - and another "landscape"-format picture for my laptop,
# to the right. It does the random landscape/portrait selection using
# aspect ratios and the command to set the background is "feh" - so without
# "feh" - https://wiki.archlinux.org/title/feh - this script will not
# work for you.
# On my system, the order in which feh applies the backgrounds to is:
# (Or maybe use "--listmonitors" if the above doesn't show you what you expect)
# 
# xrandr --listactivemonitors
# Monitors: 3
#  0: +*DP-3.8 3840/600x2160/340+0+400  DP-3.8
#  1: +DP-2 1920/344x1080/193+5280+1480  DP-2
#  2: +DP-3.1 1440/600x2560/340+3840+0  DP-3.1
#
# In my case: The second monitor/line should be the filename of the low aspect
#   ratio-image (=vertical image, fits the vertical monitor best). So
#   this script will do something like this, where the 3 images are
#   randomly picked, based on aspect ratio:
#
#  feh \
#      --bg-max ./img1_high_aspect_ratio.jpg \
#      --bg-max ./img2_low_aspect_ratio.jpg \
#      --bg-max ./img3_high_aspect_ratio.jpg
# 
# Some modifications are needed, if you have another monitor setup, 
# but this allows to randomly pick horizontal/vertical random wallpapers,
# so the displayed images best fit the screensize.
# =======================================================================

# Text file containing aspect ratios, median aspect ratio and wireless SSID (incomplete):
aspfile=aspect_ratios.txt
sortaspfile=sortedAspectList.txt
medfile=median_aspect_ratio.txt
expectedActiveMonitors=3
root_folder="$(dirname ${BASH_SOURCE})"
#debug=1 # enable debug output (non-zero length variable)

currentActMonitors=$(xrandr --listactivemonitors | grep ': +' | wc -l)
if [[ ! "$expectedActiveMonitors" == "$currentActMonitors" ]]; then
	echo "ERROR: Expected $expectedActiveMonitors monitors to be connected (check \"xrandr\"), but this seems incorrect. This script will abort now." >/dev/stderr
	exit 1
fi

# Get current SSID, which determines which background wallpapers to use:
currentSSID=$(iwgetid | grep -Po 'ESSID:"\K.*(?=")')
workFolder="$root_folder/$currentSSID"

# Error if subfolder with wallpapers named current SSID does not exist:
[ ! -d "$workFolder" ] && { \
	echo "ERROR: Current SSID is \"$currentSSID\", so wallpaper-directory" >/dev/stderr ;\
  echo "       should be: \"$workFolder\" (can also be a symlink)." >/dev/stderr ;\
  echo "       This script cannot continue." >/dev/stderr ;\
  exit 1;}

# Allow script to be called from any directory and exit to originating directory:
trap "{ popd 2>&1 >/dev/null; exit 255; }" SIGINT SIGTERM ERR EXIT
pushd "$workFolder" 1>&2 >/dev/null

# Function to read and save aspect ratios to file:
get_aspect_ratio_list() {
  if [ -n "$debug" ]; then
    echo "Getting aspect ratios (the ratio of its width to its height, w/h) and writing to \"$aspfile\"" >/dev/stderr
    echo "   (this is slow, for many wallpapers, disable if directory does not change):" >/dev/stderr
    echo " "
    echo "Re-arranging columns/format (filename first column), human-readable and writing to \"$aspfile\" --"
  fi
  find . \( -iname "*.jpg" \) -exec identify {} \; | perl -ne '/(.+?)\s+[A-Z]{3}\S?\s+(\d+)x(\d+)/; print "$1| width=$2, height=$3 |", $2/$3, "\n"' > "$aspfile"
  if [ -n "$debug" ]; then
    echo " "
  fi
}

# Determine if the file with aspect ratios should be updated/re-created - or re-used:
if test -f "$aspfile"; then
  if [ -n "$debug" ]; then
    echo "$aspfile exists inside folder: $(pwd)/ - need to test if it is old and should be updated or not..."
  fi
	if [[ $(find "$aspfile" -mtime -1 -print) ]]; then
		echo "File $filename exists and is newer than 1 day(s), thus this file will be re-used..."
		avoid_reloading_image_dimensions=true
	fi
else
  if [ -n "$debug" ]; then
	  echo "$aspfile does NOT exist inside folder: $(pwd)/ - it will be created now..."
  fi
fi

if [ "$avoid_reloading_image_dimensions" = true ]; then
  if [ -n "$debug" ]; then
    echo "No need to update/re-create the list of aspect-ratios, this time."
  fi
else
  echo "Need to update/re-create list of aspect-ratios, this could take a minute, if there are many images..."
  get_aspect_ratio_list
fi

# Sanity check:
if [ ! -s "$aspfile" ]; then echo "No input files found in \"$aspfile\", cannot continue..." >/dev/stderr; exit 1; fi

# Extract the aspect ratio column and the filename column (2 columns) + write results sorted in a file:
cat "$aspfile" | awk '{print $NF,$0}' | sort -nr | cut -f2 -d'|' > "$sortaspfile"

# This is approximately (not mathematically) the median value:
if [ ! "$avoid_reloading_image_dimensions" = true ]; then
  cat "$sortaspfile" | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }' > "$medfile"
fi
median_asp=$(cat $medfile)
if [ -n "$debug" ]; then
  echo "Median aspect ratio is (has been written to file, to avoid recalculating): $median_asp"
  echo " "
fi

# Get all lines, with aspect ratio above the median (=horisontal displays incl. laptop monitor)
highAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1>aspr) print}' | sed -r 's/\s+/\\/')

# Get all lines, with aspect ratio below the median (=vertical monitor)
lowAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1<aspr) print}' | sed -r 's/\s+/\\/')

# --- Debugging: ---
if [ -n "$debug" ]; then
  echo "---"
  echo "highAR (horizontally)="
  echo "$highAR"
  echo "---"
  echo "lowAR (vertical)="
  echo "$lowAR"
  echo "---"
fi

# === Extract 2 random lines, with "high" aspect ratio (horisontal monitors incl. laptop)
# TODO: This should/could be easier configured to match other monitor/screen configurations!
horizMonitor=$(echo "$highAR" | shuf -n 2)
if [ -n "$debug" ]; then
  echo "horizMonitor="
  echo "=========================="
  echo "$horizMonitor"
  echo " "
fi
# The \K is the short-form (and more efficient form) of (?<=pattern) which you
# use as a zero-width look-behind assertion before the text you want to output.
# (?=pattern) can be used as a zero-width look-ahead assertion after the text
# you want to output.
onlyFilesH=$(echo "$horizMonitor" | grep -Po '.*\\\K.*') 
readarray -t horizImg < <( echo "$onlyFilesH" )
if [ -n "$debug" ]; then
  echo "onlyFilesH= (array length: ${#horizImg[@]})"
  echo "$onlyFilesH"
  echo " "
  echo " Array index 0 (first element) : ${horizImg[0]}"
  echo " Array index 1 (second element): ${horizImg[1]}"
  echo " Array index 2 (second element): ${horizImg[2]}"
  echo " "
  #echo "${horizImg[*]}"
  #echo " --- horiz: ---"
  #for i in ${horizImg[@]}; do echo $i; done
  echo " "
fi

# === Extract 1 random line, with "low" aspect ratio (for vertical monitor)
# TODO: This should/could be easier configured to match other monitor/screen configurations!
vertMonitor=$(echo "$lowAR" | shuf -n 1)
if [ -n "$debug" ]; then
  echo "vertMonitor="
  echo "=========================="
  echo "$vertMonitor"
  echo " "
fi
onlyFilesV=$(echo "$vertMonitor" | grep -Po '.*\\\K.*') 
readarray -t vertImg < <( echo "$onlyFilesV" )
if [ -n "$debug" ]; then
  echo "onlyFilesV= (array length: ${#vertImg[@]})"
  echo "$onlyFilesV"
  echo " "
  echo " Array index 0 (first element) : ${vertImg[0]}"
fi


# Command-line for showing it on screen:
cmdLine="feh \\
      --bg-max \"${horizImg[0]}\" \\
      --bg-max \"${vertImg[0]}\" \\
      --bg-max \"${horizImg[1]}\""

# More debug info:
if [ -n "$debug" ]; then
  echo ' '
  echo ' '
  echo '-----------------------------------------------'
  echo "The 3 files and their aspect ratios (width/heigth) are (first line):"
  echo "  Vertical monitor. Lines 2&3 are for the normal Horiz monitors incl laptop:"
  echo "$vertMonitor" | tr '\\' ':'
  echo "$horizMonitor" | tr '\\' ':'
  echo ' '
  # Avoid 3 lines of "feh WARNING: \ does not exist - skipping" by converting
  # backslash to space:
  echo "Commandline is:"
  echo "$cmdLine"
fi

# Command-line for evaluation:
cmdLine=$(echo "$cmdLine" | tr '\\' ' ')
eval $cmdLine

