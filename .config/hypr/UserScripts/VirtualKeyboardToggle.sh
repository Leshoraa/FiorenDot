#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/virtual_keyboard_disabled"

if [ -f "$STATE_FILE" ]; then
    # Currently disabled -> Enable
    rm -f "$STATE_FILE"

    # Get monitor transform (orientation)
    TRANSFORM=$(hyprctl monitors -j | jq -r '.[] | select(.name=="eDP-1") | .transform' 2>/dev/null || echo 0)

    # If in tablet/vertical mode, start or reveal keyboard immediately
    if [ "$TRANSFORM" -ne 0 ]; then
        if pgrep -x wvkbd-mobintl >/dev/null; then
            pkill -SIGUSR2 wvkbd-mobintl
        else
            nohup wvkbd-mobintl -L 300 -H 350 >/dev/null 2>&1 &
        fi
    else
        # Normal laptop mode: run hidden so it's ready upon rotation
        if ! pgrep -x wvkbd-mobintl >/dev/null; then
            nohup wvkbd-mobintl -L 300 -H 350 --hidden >/dev/null 2>&1 &
        fi
    fi

    notify-send -u normal -h string:x-canonical-private-synchronous:vkeyboard "Virtual Keyboard" "Enabled"
else
    # Currently enabled -> Disable
    touch "$STATE_FILE"

    # Kill running virtual keyboard instance
    pkill -x wvkbd-mobintl 2>/dev/null || killall wvkbd-mobintl 2>/dev/null || true

    notify-send -u normal -h string:x-canonical-private-synchronous:vkeyboard "Virtual Keyboard" "Disabled"
fi
