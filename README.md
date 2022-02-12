# systemd_timer_change_wallpaper

This is a small illustration of how I (plan to) use systemd-timer to randomly
change the wallpaper on my 3 monitors - one of which is 90 degree rotated. The
random selection is based on width/height-aspect ratio, to best match each
monitor resolution. An illustration is shown below:

![Alt text](monitors.jpg?raw=true "Illustration of monitor setup")

I have a (newer) 4K monitor to the left. The old I had, I rotated 90 degrees -
the one shown in the middle. And then I usually have my laptop to the right.

I want the random wallpapers to match the resolution and couldn't find any
existing tools out there, so I made/created my own for the task. This is what you need to understand and run the code:

* First, verify that the script itself works - "*pick_random_wallpapers.sh*"-script.  It should fail, because it uses the SSID of your wireless network to determine which set of background images to use, so you can have a collection at work, at home - unfortunately it (at least currently) probably currently doesn't work if you're not connected to a WiFi. Feel free to fix this yourself, optionally send a pull request. The quickest and easiest solution for you is to rename the "*your-SSID-name-example-wallpapers_included*"-folder to the name of your SSID. Then run the "*pick_random_wallpapers.sh*"-script. Something should happen.

* You need to find the "feh"-command line and change this part, so it matches your monitor configuration (you probably don't have the exact same 3 monitor setup as I do). You might also want to change the number of portrait/landscape random images you need. For a 3-monitor setup like mine I have this configuration:
  
  `setbackgroundCommandLine="feh --bg-max \"%landscape\" --bg-max \"%portrait\" --bg-max \"%landscape\""`
  
  This means I use "feh" to set the background wallpaper (you don't have to use feh, you can also use another program), the first monitor has landscape-format, the second has portrait-format and the third again has landscape-format. Use "xrandr" and/or experiment to get the order right. The script will now automatically replace the <mark>%landscape</mark> and <mark>%portrait</mark> keywords with appropriate random images. If you only have 2 monitors, you only have 2 keywords instead of 3 like in my setup and so forth.

* There is also a "*systemd*"-subdirectory for an example config, that automatically calls the "*pick_random_wallpapers.sh*", e.g. every 15 minutes. First enable this, after you've verified that things are working for your particular setup.

I might not improve it further, beyond this point. If you find bugs or would like to improve it even more, please do so.
