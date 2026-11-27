#!/bin/bash
# 1. Get active wallpaper path
WALL=$(awww query 2>/dev/null | awk -F 'image: ' '{print $2}' | head -n 1)
if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    CACHE_FILE=$(find "$HOME/.cache/awww/" -type f -print -quit 2>/dev/null || true)
    [ -n "$CACHE_FILE" ] && WALL=$(awk '{print $NF}' "$CACHE_FILE")
fi
if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    WALL="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fi

# 2. Exit if missing
[ ! -f "$WALL" ] && exit 1

# 3. Downscale thumbnail to static path in /tmp
magick "$WALL" -resize 300x300 /tmp/terminal_logo.png
