#!/bin/bash
# 1. Get active wallpaper path
WALL=$(awww query | awk -F 'image: ' '{print $2}' | head -n 1)
[ -z "$WALL" ] && WALL=$(hyprctl hyprpaper listactive | awk '{print $NF}' | head -n 1)

# 2. Exit if missing
[ ! -f "$WALL" ] && exit 1

# 3. Downscale thumbnail to static path in /tmp
magick "$WALL" -resize 300x300 /tmp/terminal_logo.png
