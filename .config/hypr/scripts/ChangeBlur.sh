#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified by: Fioren (@Leshoraa)
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images"

STATE=$(hyprctl -j getoption decoration:blur:size | jq ".int")

if [ "${STATE}" -gt 6 ]; then
    hyprctl eval 'hl.config({ decoration = { blur = { size = 6, passes = 2 } } })'
    notify-send -e -u low -i "$notif/ja.png" "Blur" "⚡ Optimized Blur (Passes: 2, Size: 6)"
else
    hyprctl eval 'hl.config({ decoration = { blur = { size = 16, passes = 3 } } })'
    notify-send -e -u low -i "$notif/note.png" "Blur" "✨ Ultra Blur (Passes: 3, Size: 16)"
fi