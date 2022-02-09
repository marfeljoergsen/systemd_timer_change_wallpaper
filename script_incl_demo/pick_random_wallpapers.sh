#!/usr/bin/env bash

# Text file containing aspect ratios, median aspect ratio and wireless SSID (incomplete):
aspfile=aspect_ratios.txt
sortaspfile=sortedAspectList.txt
medfile=median_aspect_ratio.txt
expectedActiveMonitors=3

currentActMonitors=$(xrandr --listactivemonitors | grep ': +' | wc -l)
if [[ ! "$expectedActiveMonitors" == "$currentActMonitors" ]]; then
	echo "ERROR: Expected $expectedActiveMonitors monitors to be connected (check \"xrandr\"), but this seems incorrect. This script will abort now." >/dev/stderr
	exit 1
fi

#root_folder="${BASH_SOURCE}"
root_folder="$(dirname ${BASH_SOURCE})"

# Get current SSID, which determines which background wallpapers to use:
currentSSID=$(iwgetid | grep -Po 'ESSID:"\K.*(?=")')
workFolder="$root_folder/$currentSSID"
#echo workFolder=$workFolder

[ ! -d "$workFolder" ] && { \
	echo "ERROR: Current SSID is \"$currentSSID\", so wallpaper-directory" >/dev/stderr ;\
       	echo "       should be: \"$workFolder\" (can also be a symlink)." >/dev/stderr ;\
        echo "       This script cannot continue." >/dev/stderr ;\
       	exit 1;}

# For simpliticy: Setup trap - (allow script to be called from any directory
#   and exit to originating directory):
trap "{ popd 2>/dev/null; exit 255; }" SIGINT SIGTERM ERR EXIT
pushd "$workFolder" 1>&2 >/dev/null

# Function to read and save aspect ratios to file:
get_aspect_ratio_list() {
  echo "Getting aspect ratios (the ratio of its width to its height, w/h) and writing to \"$aspfile\"" >/dev/stderr
  echo "   (this is slow, for many wallpapers, disable if directory does not change):" >/dev/stderr
  # Raw input data:
  #identify -format "%[fx:abs(w/h)]: %M\n" *.jpg
  
  # WARNING: THIS DOES NOT DEAL WITH SPACES IN FILENAMES:
  #for f in $(ls *.jpg); do
  #      identify -format "%[fx:abs(w/h)]: %M\n" "$f"; 
  #done 
  # Find the aspect ratios (w/h) from each file using "identify":
  #   (in the output, Col.1 = aspect ratio, col.2 = filename)
  echo " "
  echo "Re-arranging columns/format (filename first column), human-readable and writing to \"$aspfile\" --"
  #find . \( -iname "*.jpg" \) -exec identify {} \; | perl -ne '/(.+?)\s+[A-Z]{3}\S?\s+(\d+)x(\d+)/; print "$1| width=$2, height=$3 |", $2/$3, "\n"' | tee "$aspfile"
  find . \( -iname "*.jpg" \) -exec identify {} \; | perl -ne '/(.+?)\s+[A-Z]{3}\S?\s+(\d+)x(\d+)/; print "$1| width=$2, height=$3 |", $2/$3, "\n"' > "$aspfile"
  echo " "
}

# Determine if the file with aspect ratios should be updated/re-created - or re-used:
if test -f "$aspfile"; then
	echo "$aspfile exists inside folder: $(pwd)/ - need to test if it is old and should be updated or not..."
	if [[ $(find "$aspfile" -mtime -1 -print) ]]; then
		echo "File $filename exists and is newer than 1 day(s), thus this file will be re-used..."
		avoid_reloading_image_dimensions=true
	fi
else
	echo "$aspfile does NOT exist inside folder: $(pwd)/ - it has to be created now.."
fi

if [ "$avoid_reloading_image_dimensions" = true ]; then
  echo "The \"avoid_reloading_image_dimensions\"-option is in use - disable this if directory changes"
else
  echo "Need to update/re-create list of aspect-ratios..."
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
echo "Median aspect ratio is (has been written to file, to avoid recalculating): $median_asp"
echo " "

# This correctly only prints, if aspect ratio is above/below the value "1"
#cat "$sortaspfile" | awk -F' ' '{if($1>1)print$1 " " $2}'
#cat "$sortaspfile" | awk -F' ' '{if($1<1)print$1 " " $2}'

# Print all lines, with aspect ratio above the median (=horisontal displays incl. laptop monitor)
#highAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1>aspr)print$1 " " $2}')
highAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1>aspr) print}' | sed -r 's/\s+/\\/')

# Print all lines, with aspect ratio below the median (=vertical monitor)
#lowAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1<aspr)print$1 " " $2}')
lowAR=$(cat "$sortaspfile" | awk -v aspr=$median_asp -F' ' '{if($1<aspr) print}' | sed -r 's/\s+/\\/')

# --- debugging: ---
if false; then
  echo "---"
  echo "highAR (horizontally)="
  echo "$highAR"
  echo "---"
  echo "lowAR (vertical)="
  echo "$lowAR"
  echo "---"
fi
# ---- Pick 3 random files: ----
#shuf -ezn 3 *.jpg | xargs -0 -n1 echo

# === Extract 2 random lines, with "high" aspect ratio (horisontal monitors incl. laptop)
#echo " --- highAR: ---"
#echo "$highAR"
#echo " "
horizMonitor=$(echo "$highAR" | shuf -n 2)
echo "horizMonitor="
echo "=========================="
echo "$horizMonitor"
echo " "
# Below contains both columns
#readarray -t horizImg < <( echo $horizMonitor )
#echo " "
# We only want the filename column (#2) now:
#readarray -t horizImg < <( echo "$horizMonitor" )
#readarray -t horizImg < <( echo "$horizMonitor" | tr '\n' '=' )

#onlyFilesH=$(echo "$horizMonitor" | awk '{print ""}{for(i=2;i<=NF;++i)printf $i" "}' )
# The \K is the short-form (and more efficient form) of (?<=pattern) which you
# use as a zero-width look-behind assertion before the text you want to output.
# (?=pattern) can be used as a zero-width look-ahead assertion after the text
# you want to output.
onlyFilesH=$(echo "$horizMonitor" | grep -Po '.*\\\K.*') 
readarray -t horizImg < <( echo "$onlyFilesH" )
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

# === Extract 1 random line, with "low" aspect ratio (for vertical monitor)
vertMonitor=$(echo "$lowAR" | shuf -n 1)
echo "vertMonitor="
echo "=========================="
echo "$vertMonitor"
echo " "

#onlyFilesV=$(echo "$vertMonitor" | while read c1 c2; do echo $c2; done)
# The \K is the short-form (and more efficient form) of (?<=pattern) which you
# use as a zero-width look-behind assertion before the text you want to output.
# (?=pattern) can be used as a zero-width look-ahead assertion after the text
# you want to output.
onlyFilesV=$(echo "$vertMonitor" | grep -Po '.*\\\K.*') 

readarray -t vertImg < <( echo "$onlyFilesV" )
echo "onlyFilesV= (array length: ${#vertImg[@]})"
echo "$onlyFilesV"
echo " "
echo " Array index 0 (first element) : ${vertImg[0]}"
#--

# This is the order in which feh applies the backgrounds too:
# 
# xrandr --listactivemonitors
# Monitors: 3
#  0: +*DP-3.8 3840/600x2160/340+0+400  DP-3.8
#  1: +DP-2 1920/344x1080/193+5280+1480  DP-2
#  2: +DP-3.1 1440/600x2560/340+3840+0  DP-3.1
# 
# Or maybe use "--listmonitors" if the above doesn't show you what you expect:
# xrandr --listmonitors
# Monitors: 3
#  0: +*DP-3.8 3840/600x2160/340+0+400  DP-3.8
#  1: +DP-2 1920/344x1080/193+5280+1480  DP-2
#  2: +DP-3.1 1440/600x2560/340+3840+0  DP-3.1

#=========

# In my case: The second monitor/line should be the filename of the low aspect
#   ratio-image (=vertical image, fits the vertical monitor best):
#
#  feh \
#      --bg-max ./img1.jpg \
#      --bg-max ./img2_low_aspect_ratio.jpg \
#      --bg-max ./img3.jpg
# 
# The "bg-max" maximizes - and still preserves aspect ratio.

# ===============================
# Show some debug info (TODO: remove this):
echo ' '
echo ' '
echo '-----------------------------------------------'
echo "The 3 files and their aspect ratios (width/heigth) are (first line):"
echo "  Vertical monitor. Lines 2&3 are for the normal Horiz monitors incl laptop:"
# Do not indent here, or the third line of the output (for horizMonitor) will
# not be indented, looking kind of silly...:
echo "$vertMonitor" | tr '\\' ':'
echo "$horizMonitor" | tr '\\' ':'
echo ' '
cmdLine="feh \\
      --bg-max \"${horizImg[0]}\" \\
      --bg-max \"${vertImg[0]}\" \\
      --bg-max \"${horizImg[1]}\""

# Avoid 3 lines of "feh WARNING: \ does not exist - skipping" by converting
# backslash to space:
echo "Commandline is:"
echo "$cmdLine"
cmdLine=$(echo "$cmdLine" | tr '\\' ' ')

#echo "(DEBUG): Commandline for evaluation:"
#echo "$cmdLine"

eval $cmdLine

