# systemd_timer_change_wallpaper

This is a small illustration of how I (plan to) use systemd-timer to randomly
change the wallpaper on my 3 monitors - one of which is 90 degree rotated. The
random selection is based on width/height-aspect ratio, to best match each
monitor resolution. An illustration is shown below:

![Alt text](monitors.jpg?raw=true "Illustration of monitor setup")

I have a (newer) 4K monitor to the left. The old I had, I rotated 90 degrees -
the one shown in the middle. And then I usually have my laptop to the right.

I want the random wallpapers to match the resolution and couldn't find any
existing tools out there, so I made/created my own for the task. The code is
not pretty - because I did this in my valuable sparetime - but it basically
works and does the job.



**WARNING:** *This project is incomplete and still contains a lot of temporary
comments/stuff - it might never be finished!*
