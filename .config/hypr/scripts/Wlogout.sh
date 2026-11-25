#!/usr/bin/env bash

# Rofi power menu theme
THEME="$HOME/.config/rofi/powermenu.rasi"

# Option Icons (Nerd Font)
lock="󰌾"
logout="󰍃"
sleep="󰤄"
reboot="󰑓"
shutdown="󰐥"

# Menu entries
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

# Prompt via Rofi
selected_option=$(echo -e "$options" | rofi -dmenu \
                  -i \
                  -selected-row 2 \
                  -p "Session Menu" \
                  -theme "$THEME")

# Execute action
case "$selected_option" in
    "$lock")
        hyprlock
        ;;
    "$logout")
        hyprctl eval 'hl.dispatch(hl.dsp.exit())'
        ;;
    "$sleep")
        systemctl suspend
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac