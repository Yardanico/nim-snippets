# Scripts/settings for visualizing Nim git repo with Gource



```
# For Arch
sudo pacman -Sy gource
git clone https://github.com/nim-lang/nim
```

https://github.com/acaudwell/Gource/wiki/Gravatar-Example - Getting the list of all contributors with their emails

```
# Reverse order so the last entry is the newest ones
# so that we can use the last email for a user
git -C nim log --pretty=format:"%ae:%an" | tac > users.txt
```

```
# Convert Nim repo into a custom log (so that we can replace users)
gource --output-custom-log nimrepo.txt nim

# Do the actual replacement
nim c -r gravatar.nim

# Start gource with the config file
gource --load-config gource.cfg
```



Full Gource help:
```
Gource v0.51
Usage: gource [options] [path]

Options:
  -h, --help                       Help

  -WIDTHxHEIGHT, --viewport        Set viewport size
  -f, --fullscreen                 Fullscreen
      --screen SCREEN              Screen number
      --multi-sampling             Enable multi-sampling
      --no-vsync                   Disable vsync

  --start-date 'YYYY-MM-DD hh:mm:ss +tz'  Start at a date and optional time
  --stop-date  'YYYY-MM-DD hh:mm:ss +tz'  Stop at a date and optional time

  -p, --start-position POSITION    Start at some position (0.0-1.0 or 'random')
      --stop-position  POSITION    Stop at some position
  -t, --stop-at-time SECONDS       Stop after a specified number of seconds
      --stop-at-end                Stop at end of the log
      --dont-stop                  Keep running after the end of the log
      --loop                       Loop at the end of the log

  -a, --auto-skip-seconds SECONDS  Auto skip to next entry if nothing happens
                                   for a number of seconds (default: 3)
      --disable-auto-skip          Disable auto skip
  -s, --seconds-per-day SECONDS    Speed in seconds per day (default: 10)
      --realtime                   Realtime playback speed
      --no-time-travel             Use the time of the last commit if the
                                   time of a commit is in the past
  -c, --time-scale SCALE           Change simulation time scale (default: 1.0)
  -e, --elasticity FLOAT           Elasticity of nodes (default: 0.0)

  --key                            Show file extension key

  --user-image-dir DIRECTORY       Dir containing images to use as avatars
  --default-user-image IMAGE       Default user image file
  --colour-images                  Colourize user images

  -i, --file-idle-time SECONDS     Time files remain idle (default: 0)

  --max-files NUMBER      Max number of files or 0 for no limit
  --max-file-lag SECONDS  Max time files of a commit can take to appear

  --log-command VCS       Show the VCS log command (git,svn,hg,bzr,cvs2cl)
  --log-format  VCS       Specify the log format (git,svn,hg,bzr,cvs2cl,custom)

  --load-config CONF_FILE  Load a config file
  --save-config CONF_FILE  Save a config file with the current options

  -o, --output-ppm-stream FILE    Output PPM stream to a file ('-' for STDOUT)
  -r, --output-framerate  FPS     Framerate of output (25,30,60)

Extended Options:

  --window-position XxY    Initial window position
  --frameless              Frameless window

  --output-custom-log FILE  Output a custom format log file ('-' for STDOUT).

  -b, --background-colour  FFFFFF    Background colour in hex
      --background-image   IMAGE     Set a background image

  --bloom-multiplier       Adjust the amount of bloom (default: 1.0)
  --bloom-intensity        Adjust the intensity of the bloom (default: 0.75)

  --camera-mode MODE       Camera mode (overview,track)
  --crop AXIS              Crop view on an axis (vertical,horizontal)
  --padding FLOAT          Camera view padding (default: 1.1)

  --disable-auto-rotate    Disable automatic camera rotation

  --disable-input          Disable keyboard and mouse input

  --date-format FORMAT     Specify display date string (strftime format)

  --font-file FILE         Specify the font
  --font-scale SCALE       Scale the size of all fonts
  --font-size SIZE         Font size used by date and title
  --file-font-size SIZE    Font size for filenames
  --dir-font-size SIZE     Font size for directory names
  --user-font-size SIZE    Font size for user names
  --font-colour FFFFFF     Font colour used by date and title in hex

  --file-extensions          Show filename extensions only
  --file-extension-fallback  Use filename as extension if the extension
                             is missing or empty

  --git-branch             Get the git log of a particular branch

  --hide DISPLAY_ELEMENT   bloom,date,dirnames,files,filenames,mouse,progress,
                           root,tree,users,usernames

  --logo IMAGE             Logo to display in the foreground
  --logo-offset XxY        Offset position of the logo

  --loop-delay-seconds SECONDS Seconds to delay before looping (default: 3)

  --title TITLE            Set a title

  --transparent            Make the background transparent

  --user-filter REGEX      Ignore usernames matching this regex
  --user-show-filter REGEX Show only usernames matching this regex

  --file-filter REGEX      Ignore file paths matching this regex
  --file-show-filter REGEX Show only file paths matching this regex

  --user-friction SECONDS  Change the rate users slow down (default: 0.67)
  --user-scale SCALE       Change scale of users (default: 1.0)
  --max-user-speed UNITS   Speed users can travel per second (default: 500)

  --follow-user USER       Camera will automatically follow this user
  --highlight-dirs         Highlight the names of all directories
  --highlight-user USER    Highlight the names of a particular user
  --highlight-users        Highlight the names of all users

  --highlight-colour       Font colour for highlighted users in hex.
  --selection-colour       Font colour for selected users and files.
  --filename-colour        Font colour for filenames.
  --dir-colour             Font colour for directories.

  --dir-name-depth DEPTH    Draw names of directories down to a specific depth.
  --dir-name-position FLOAT Position along edge of the directory name
                            (between 0.0 and 1.0, default is 0.5).

  --filename-time SECONDS  Duration to keep filenames on screen (default: 4.0)

  --caption-file FILE         Caption file
  --caption-size SIZE         Caption font size
  --caption-colour FFFFFF     Caption colour in hex
  --caption-duration SECONDS  Caption duration (default: 10.0)
  --caption-offset X          Caption horizontal offset

  --hash-seed SEED         Change the seed of hash function.

  --path PATH

PATH may be a supported version control directory, a log file, a gource config
file, or '-' to read STDIN. If omitted, gource will attempt to generate a log
from the current directory.
```