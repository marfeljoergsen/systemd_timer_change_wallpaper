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

printhelp(){
  echo " "
  echo "                ====================="
  echo "                --- INSTRUCTIONS: ---"
  echo "                ====================="
  echo "Run the script without any arguments and the default behaviour"
  echo "is to look for wallpapers in a subfolder of the script location,"
  echo "corresponding to the currently connected wireless network (SSID)."
  echo "This way you can have several different configurations or set"
  echo "of wallpapers, e.g. home/office etc. The script will automatically"
  echo "pick a random wallpaper once executed (e.g. via systemd-service"
  echo "every 15 minutes or how often you prefer to have your desktop"
  echo "background/wallpaper renewed). Optional arguments:"
  echo " "
  echo " -h           : Print this help message"
  echo " -d (dir)     : Specify a directory to use, instead of the SSID-name"
  echo ' -n "expr=dir": Specify a commandline for LAN-test and use "dir" if no errors (ret code=0)'.
  echo '                WARNING: You need "=dir", where "dir" is a subdirectory/symlink to wallpapers!'.
  echo '       Example: -n "nmcli dev wifi | grep -qi machine_iot_5g && iwlist scan 2>&1 | grep -qi machine_iot_5g=Machine" (one long string)'
  echo '       Example: -n "ping -c 1 192.168.1.1 >/dev/null && arp |grep -i '\'192.168.1.1\''|grep -oP '\'\\w{2}:\\w{2}:\\w{2}:\\w{2}:\\w{2}:\\w{2}\'' | grep -qi '\'ab:cd:ef:12:34:56\''=Machine" (one long string)'
  echo " -c           : Specify a commandline for setting the background."
  echo "                The alternative is to change this commandline, by"
  echo "                editing the script. But for different locations (e.g." 
  echo "                laptops being moved around), this isn't ideal... Example:"
  echo "    $0 -c 'feh --bg-max \"%landscape\" --bg-max \"%portrait\" --bg-max \"%landscape'"
  echo "            It's important with the surrounding single quotes and inside"
  echo "            double quotes, for each monitor-format: portrait/landscape."
  echo " "
}

if [ "$#" -eq 0 ]; then
  echo " --- NB: \"Use $0 -h\" to print help (instructions) message ---"
else
  while getopts hd:c:n: flag
  do
      case "${flag}" in
          h) printhelp;;
          d) dir=${OPTARG};;
          c) cmdlineInput=${OPTARG};;
          n) LANtestInput=${OPTARG};;
          *) echo " * ERROR: Invalid/unknown option. Use \"-h\" for help." >&2; exit 1;;
      esac
  done
fi

#setbackgroundCommandLine="/usr/bin/feh \\
[ -n "$cmdlineInput" ] && setbackgroundCommandLine="$cmdlineInput" || 
  setbackgroundCommandLine="feh \\
        --bg-max \"%landscape\" \\
        --bg-max \"%portrait\" \\
        --bg-max \"%landscape\""

# Text file containing aspect ratios, median aspect ratio and wireless SSID (incomplete):
aspfile=aspect_ratios.txt
sortaspfile=sortedAspectList.txt
medfile=median_aspect_ratio.txt
root_folder="$(dirname ${BASH_SOURCE})"
#debug=1 # enable debug output (non-zero length variable)
#extraverbose=1 # extra details, if debug is enabled

# Sanity check:
backgroundUtil=$(echo "$setbackgroundCommandLine" | grep -Po '^[\w/]+\b')
if [ -n "$debug" ]; then
  echo "backgroundUtil=$backgroundUtil"
fi
# Test if (directly) executable:
if [[ -f "$backgroundUtil" && -x $(realpath "$backgroundUtil") ]]; then
  if [ -n "$debug" ]; then
    echo "OK: $backgroundUtil is executable..."
  fi
else # Test if in path - error if neither executable nor in path:
  #$(which "$backgroundUtil" 2>/dev/null) || { echo "ERROR: The utility \"$backgroundUtil\"" \
  $(which "$backgroundUtil" 2>/dev/null >/dev/null) || { echo "ERROR: The utility \"$backgroundUtil\"" \
    "is not an executable and it does not exist in path! Cannot continue, please fix!" \
    >&2 ; exit 1;}
  if [ -n "$debug" ]; then
    echo "OK: $backgroundUtil is in the path..."
  fi
fi

# Deduce how many landscape/portrait random images are needed:
expectedActiveMonitors=$(echo "$setbackgroundCommandLine" |grep -Poi '"(\%landscape|\%portrait)"' | wc -w)
nLand=$(echo "$setbackgroundCommandLine" |grep -Poi '"\%landscape"' | wc -w)
nPort=$(echo "$setbackgroundCommandLine" |grep -Poi '"\%portrait"' | wc -w)
if [ -n "$debug" ]; then
  echo " "
  echo " - expectedActiveMonitors=$expectedActiveMonitors"
  echo " - nLand=$nLand"
  echo " - nPort=$nPort"
fi
# Check that number of active monitors corresponds to what is expected:
currentActMonitors=$(xrandr --listactivemonitors | grep ': +' | wc -l)
if [[ ! "$expectedActiveMonitors" == "$currentActMonitors" ]]; then
	echo "ERROR: Expected $expectedActiveMonitors monitors to be connected (check \"xrandr\"), but this seems incorrect. This script will abort now." >&2
	exit 1
fi


# Get working folder containing images/wallpapers (by default
# this folder is the same as the connected wireless SSID
[ -z "$LANtestInput" ] && {
[ -n "$dir" ] && workFolder="$dir" || {
  currentSSID=$(iwgetid | grep -Po 'ESSID:"\K.*(?=")')
  workFolder="$root_folder/$currentSSID";}
} || {
  lantest="${LANtestInput%=*}"
  landir="${LANtestInput#*=}"
  eval "$lantest"
  rcode="$?"
  [[ "$rcode" == "0" ]] && workFolder="$root_folder/$landir"
}

# Error if subfolder with wallpapers does not exist - nested:
[ ! -d "$workFolder" ] && { \
 	echo "ERROR: Expected subfolder name: \"$workFolder\" to exist (with wallpapers, it can also be a symlink)." >&2
  echo "       Current working directory: \"$(pwd)\"." >&2
  echo "       This script cannot continue due to this problem." >&2 ; exit 1;
}

# Allow script to be called from any directory and exit to originating directory:
trap "{ popd 2>&1 >/dev/null; exit 255; }" SIGINT SIGTERM ERR
trap "{ popd 2>&1 >/dev/null; exit 0; }" EXIT
pushd "$workFolder" 1>&2 >/dev/null

# Modify "aspfile"-variable, so it stores its temporary files inside /tmp:
filePrefix="/tmp/$(echo $(basename $workFolder) | tr '/' '_')_"
aspfile="$filePrefix$aspfile"
sortaspfile="$filePrefix$sortaspfile"
medfile="$filePrefix$medfile"
if [ -n "$debug" ]; then
  echo aspfile=$aspfile
  echo sortaspfile=$sortaspfile
  echo medfile=$medfile
fi

# Function to read and save aspect ratios to file:
get_aspect_ratio_list() {
  if [ -n "$debug" ]; then
    echo "Getting aspect ratios (the ratio of its width to its height, w/h) and writing to \"$aspfile\"" >&2
    echo "   (this is slow, for many wallpapers, disable if directory does not change):" >&2
    echo " "
    echo "Re-arranging columns/format (filename first column), human-readable and writing to \"$aspfile\" --"
  fi
  find . \( -iname "*.jpg" \) -exec identify {} \; 2>/dev/null | perl -ne '/(.+?)\s+[A-Z]{3}\S?\s+(\d+)x(\d+)/; print "$1| width=$2, height=$3 |", $2/$3, "\n"' > "$aspfile"
  if [ -n "$debug" ]; then
    echo " "
  fi
}

# Determine if the file with aspect ratios should be updated/re-created - or re-used:
if test -f "$aspfile"; then
  if [ -n "$debug" ]; then
    echo " "
    echo "INFO: \"$aspfile\" exists inside folder: $(pwd)/"
  fi
	if [[ $(find "$aspfile" -mtime -1 -print) ]]; then
		echo " * File: \"$aspfile\" exists and is newer than 1 day(s), thus this file will be re-used..."
		avoid_reloading_image_dimensions=true
	fi
else
  if [ -n "$debug" ]; then
	  echo " * File: \"$aspfile\" does NOT exist inside folder: $(pwd)/ - it will be created now..."
  fi
fi

if [ "$avoid_reloading_image_dimensions" = true ]; then
  if [ -n "$debug" ]; then
    echo " * No need to update/re-create the list of aspect-ratios, this time."
  fi
else
  echo " * Need to update/re-create list of aspect-ratios, this could take a minute, if there are many images..."
  get_aspect_ratio_list
fi

# Sanity check:
if [ ! -s "$aspfile" ]; then echo "No input files found in \"$aspfile\", cannot continue..." >&2; exit 1; fi

# Extract the aspect ratio column and the filename column (2 columns) + write results sorted in a file:
cat "$aspfile" | awk '{print $NF,$0}' | sort -nr | cut -f2 -d'|' > "$sortaspfile"

# This is approximately (not mathematically) the median value:
if [ ! "$avoid_reloading_image_dimensions" = true ]; then
  cat "$sortaspfile" | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }' > "$medfile"
fi
median_asp=$(cat $medfile)
if [ -n "$debug" ]; then
  echo " "
  echo "Median aspect ratio is: $median_asp (this value has been written to file, to avoid recalculating)"
  echo " "
fi

# Get all lines, with aspect ratio above the median (=horisontal displays incl. laptop monitor)
highAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1>aspr) print}' | sed -r 's/\s+/\\/')
[[ -z "$highAR" ]] && { echo "ERROR: No high aspect ratio random images found. Please check \"$sortaspfile\" and ensure there are enough images to choose among, above median aspect ratio \"$medfile\". Add images, if insufficient. Cannot continue now..." >&2; exit 1; }

# Get all lines, with aspect ratio below the median (=vertical monitor)
lowAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1<aspr) print}' | sed -r 's/\s+/\\/')
[[ -z "$lowAR" ]] && { echo "ERROR: No low aspect ratio random images found. Please check \"$sortaspfile\" and ensure there are enough images to choose among, below median aspect ratio \"$medfile\". Add images, if insufficent. Cannot continue..." >&2; exit 1; }

# --- Debugging - NORMALLY NOT RELEVANT (requires extraverbose to show): ---
if [ -n "$debug" ] && [ -n "$extraverbose" ]; then
  echo "---"
  echo "highAR (horizontally)="
  echo "$highAR"
  echo "---"
  echo "lowAR (vertical)="
  echo "$lowAR"
  echo "---"
fi

# === Extract $nLand random line(s), with "high" aspect ratio (horisontal monitors incl. laptop)
#     ---*** LANDSCAPE ***---
horizMonitor=$(echo "$highAR" | shuf -n "$nLand")
[[ -z "$horizMonitor" ]] && { echo "ERROR: No horizontal random images found - possible internal error; cannot continue..." >&2; exit 1; }
if [ -n "$debug" ]; then
  echo " "
  echo "horizMonitor="
  echo "=========================="
  if [ -n "$extraverbose" ]; then
    echo "$horizMonitor"
    echo " "
  fi
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
  echo " - Array index 0 (first element) : ${horizImg[0]}"
  echo " - Array index 1 (second element): ${horizImg[1]}"
  echo " - Array index 2 (third element) : ${horizImg[2]}"
  echo " - Array index 3 (fourth element): ${horizImg[3]}"
  echo " "
  #echo "${horizImg[*]}"
  #echo " --- horiz: ---"
  #for i in ${horizImg[@]}; do echo $i; done
  echo " "
fi

# === Extract $nPort random line(s), with "low" aspect ratio (for vertical monitor)
#     ---*** PORTRAIT ***---
vertMonitor=$(echo "$lowAR" | shuf -n "$nPort")
[[ -z "$vertMonitor" ]] && { echo "ERROR: No vertical random images found - possible internal error; cannot continue..." >&2; exit 1; }
if [ -n "$debug" ]; then
  echo "vertMonitor="
  echo "=========================="
  if [ -n "$extraverbose" ]; then
    echo "$vertMonitor"
    echo " "
  fi
fi
onlyFilesV=$(echo "$vertMonitor" | grep -Po '.*\\\K.*') 
readarray -t vertImg < <( echo "$onlyFilesV" )
if [ -n "$debug" ]; then
  echo "onlyFilesV= (array length: ${#vertImg[@]})"
  echo "$onlyFilesV"
  echo " "
  echo " - Array index 0 (first element) : ${vertImg[0]}"
  echo " - Array index 1 (second element): ${vertImg[1]}"
  echo " - Array index 2 (third element) : ${vertImg[2]}"
  echo " - Array index 2 (fourth element): ${vertImg[3]}"
fi

# ====== String substitution, to generate command-line for setting backgrounds ======
# Landscape-replacement:
cmdLine="$setbackgroundCommandLine"
if [ -n "$debug" ]; then
  echo ' '
  echo ' '
  echo '---------------------'
  echo "cmdLine=$cmdLine"
  echo " "
fi
for i in ${!horizImg[@]}; do
  if [ -n "$debug" ]; then
    echo " SUBSTITUTION: %landscape => \"${horizImg[$i]}\""
  fi
  cmdLine=$(echo "$cmdLine" | sed -z 's|%landscape|'"${horizImg[$i]}"'|')
done

# Portrait-replacement:
for i in ${!vertImg[@]}; do
  if [ -n "$debug" ]; then
    echo " SUBSTITUTION: %portrait => \"${vertImg[$i]}\""
  fi
  cmdLine=$(echo "$cmdLine" | sed -z 's|%portrait|'"${vertImg[$i]}"'|')
done


# More debug info:
if [ -n "$debug" ]; then
  echo ' '
  echo ' '
  echo '-----------------------------------------------'
  echo "The files used and their aspect ratios (width/heigth) are:"
  echo ' '
  echo " *** Vertical/portrait mode monitor(s): ***"
  echo "$vertMonitor" | tr '\\' ':'
  echo ' '
  echo " *** Horizontal/landscape mode monitor(s): ***"
  echo "$horizMonitor" | tr '\\' ':'
  echo ' '
fi

# Write commandline to screen, for copy/pasting and manual testing:
if [ -n "$debug" ]; then
  echo '---------------------'
  echo " "
  echo " "
fi
echo "cmdLine=$cmdLine"

# === Command-line for evaluation: ===
# Avoid 3 lines of "feh WARNING: \ does not exist - skipping" by converting
# backslash to space:
cmdLine=$(echo "$cmdLine" | tr '\\' ' ')
eval $cmdLine

