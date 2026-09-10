#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

PROCESS="hypridle"

if [[ "$1" == "status" ]]; then
    if pgrep -x "$PROCESS" >/dev/null; then
        echo '{"text": " ", "class": "deactivated", "tooltip": "Hypridle Active"}'
    else
        echo '{"text": " ", "class": "activated", "tooltip": "Hypridle Deactive"}'
    fi
elif [[ "$1" == "toggle" ]]; then
    if pgrep -x "$PROCESS" >/dev/null; then
        pkill "$PROCESS"
        notify-send -u low "Hypridle Deactive"
    else
        hypridle > /dev/null 2>&1 & 
        notify-send -u low "Hypridle Active"
    fi
else
    echo "Usage: $0 {status|toggle}"
    exit 1
fi