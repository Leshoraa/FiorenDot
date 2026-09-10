#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master, Dwindle, Scrolling, or Monocle) on the fly

notif="$HOME/.config/swaync/images/ja.png"

# Ambil layout saat ini
LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
    # Dari Master pindah ke Dwindle
    hyprctl keyword general:layout dwindle
    hyprctl keyword bind SUPER,O,togglesplit
    notify-send -e -u low -i "$notif" "Dwindle Layout"
    ;;
"dwindle")
    # Dari Dwindle pindah ke Scrolling
    hyprctl keyword general:layout scrolling
    hyprctl keyword unbind SUPER,O
    notify-send -e -u low -i "$notif" "Scrolling Layout"
    ;;
"scrolling")
    # Dari Scrolling pindah ke Monocle
    hyprctl keyword general:layout monocle
    notify-send -e -u low -i "$notif" "Monocle Layout"
    ;;
"monocle")
    # Dari Monocle balik ke Master
    hyprctl keyword general:layout master
    notify-send -e -u low -i "$notif" "Master Layout"
    ;;
*)
    # Fallback jika terjadi error
    hyprctl keyword general:layout dwindle
    notify-send -e -u low -i "$notif" "Reset to Dwindle Layout"
    ;;
esac