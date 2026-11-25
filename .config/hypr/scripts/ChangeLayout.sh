#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified by: Fioren (@Leshoraa)
# for changing Hyprland Layouts (Master, Dwindle, Scrolling, or Monocle) on the fly

notif="$HOME/.config/swaync/images/ja.png"

# Get current layout
LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
    # Master -> Dwindle
    hyprctl eval 'hl.config({ general = { layout = "dwindle" } }); hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
    notify-send -e -u low -i "$notif" "Dwindle Layout"
    ;;
"dwindle")
    # Dwindle -> Scrolling
    hyprctl eval 'hl.config({ general = { layout = "scrolling" } }); hl.unbind("SUPER + O")'
    notify-send -e -u low -i "$notif" "Scrolling Layout"
    ;;
"scrolling")
    # Scrolling -> Monocle
    hyprctl eval 'hl.config({ general = { layout = "monocle" } })'
    notify-send -e -u low -i "$notif" "Monocle Layout"
    ;;
"monocle")
    # Monocle -> Master
    hyprctl eval 'hl.config({ general = { layout = "master" } })'
    notify-send -e -u low -i "$notif" "Master Layout"
    ;;
*)
    # Fallback
    hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
    notify-send -e -u low -i "$notif" "Reset to Dwindle Layout"
    ;;
esac