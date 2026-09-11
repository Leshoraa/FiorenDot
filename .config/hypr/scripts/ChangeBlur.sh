#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images"

STATE=$(hyprctl -j getoption decoration:blur:size | jq ".int")

if [ "${STATE}" -gt 6 ]; then
    hyprctl keyword decoration:blur:size 6
    hyprctl keyword decoration:blur:passes 2
    notify-send -e -u low -i "$notif/ja.png" "Blur" "⚡ Optimized Blur (Passes: 2, Size: 6)"
else
    hyprctl keyword decoration:blur:size 16
    hyprctl keyword decoration:blur:passes 3
    notify-send -e -u low -i "$notif/note.png" "Blur" "✨ Ultra Blur (Passes: 3, Size: 16)"
fi