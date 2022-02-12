# systemd_timer_change_wallpaper (get random background image, with proper aspect ratio for each monitor - everytime the script is being run, via systemd-timer)

***<u>Problem: </u>***I wanted random wallpaper-images to match the aspect ratio of my connected monitors and couldn't find any existing tools out there, so I made/created my own script, that does the task.

![Alt text](monitors.jpg?raw=true "Illustration of monitor setup")

Above is a small illustration of how I use systemd-timer to randomly change the
wallpaper on my 3 monitors - one of which is 90 degrees rotated (the reason
I made this script). The random selection of current background among wallpaper-images, is based on the width/height-aspect ratio of each image, to best match each monitor resolution.

In my setup, I have a (newer) 4K monitor to the left. The old I had, I rotated 90 degrees (the one shown in the middle). And then I usually have my laptop to the right. To quickly get started, try running:

```
./pick_random_wallpapers.sh -d your-SSID-name-example-wallpapers_included

* Need to update/re-create list of aspect-ratios, this could take a minute, if there are many images...
  cmdLine=feh \

       --bg-max "./horiz_600x350.jpg" \
       --bg-max "./vertMonitor_300x500.jpg" \
       --bg-max "./horizMonitor_750x500.jpg"
```

This will however probably not work for you, because your setup is different, so you need to modify the commandline for setting the background.

Use <mark>./pick_random_wallpapers.sh -h</mark> for help on the (few available) optional commandline arguments. I suggest you:

* First, run the "*pick_random_wallpapers.sh*"-script.  It should fail, because it uses the
  SSID of your wireless network to determine which set of background images to
  use. You can choose to have a collection of background images at work and at home - and other places - or always just use the <mark>-d</mark> option, for specifying the directory of your background images/wallpapers.

* You need to figure out which command line works for setting background on your displays or connected monitors. For a 3-monitor setup like mine I have this configuration:
  
  `setbackgroundCommandLine="feh --bg-max \"%landscape\" --bg-max \"%portrait\" --bg-max \"%landscape\""`
  
  This means I use "feh" to set the background wallpaper (you don't have to use
  feh, you can also use another program), the first monitor has landscape-format,
  the second has portrait-format and the third again has landscape-format. Use
  "xrandr" and/or experiment to get the order right. The script will now
  automatically replace the <mark>%landscape</mark> and <mark>%portrait</mark>
  keywords with appropriate random images. If you only have 2 monitors, you only
  have 2 keywords instead of 3 like in my setup and so forth - if you only have a laptop screen, you might just use e.g: <mark>./pick_random_wallpapers.sh -c 'feh --bg-max "%landscape"'</mark> - NB: It's important with the surrounding single quotes and inside double quote(s), for each monitor-format: portrait/landscape (due to how bash works and handles commandline arguments). You can also hardcode the commandline inside the script...

* There is also a "*systemd*"-subdirectory illustrating an example config, that
  automatically calls the "*pick_random_wallpapers.sh*", e.g. every 15 minutes.
  First enable this, after you've verified that things are working for your
  particular setup and with the commandline options/setup you wish to use.

If you find bugs or would like to improve it even more, please do so (maybe
even write to me/send a pull request) - on the other hand, I think it's limited how much further this can be improved - it does the job for me...
