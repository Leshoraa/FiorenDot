#!/usr/bin/env bash

# Path Tema Rofi
THEME="$HOME/.config/rofi/powermenu.rasi"

# Option Icons (Nerd Font)
lock="󰌾"
logout="󰍃"
sleep="󰤄"
reboot="󰑓"
shutdown="󰐥"

# Gabungkan Opsi
# Gabungkan Opsi (Urutan Baru)
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

# Ambil pilihan dari Rofi
selected_option=$(echo -e "$options" | rofi -dmenu \
                  -i \
                  -selected-row 2 \
                  -p "See you later, $(whoami)!" \
                  -theme "$THEME")

# Perintah Eksekusi
case "$selected_option" in
    "$lock")
        hyprlock
        ;;
    "$logout")
        hyprctl dispatch exit
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