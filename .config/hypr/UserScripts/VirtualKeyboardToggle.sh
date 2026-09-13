#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/virtual_keyboard_state"
WVKBD_BIN="$HOME/.local/bin/wvkbd-mobintl"

send_notify() {
    notify-send -u normal -i "" -h string:x-canonical-private-synchronous:vkeyboard -a "Virtual Keyboard" "$1" "$2"
}

if ! pgrep -x wvkbd-mobintl >/dev/null; then
    # Not running -> Launch it visible
    hyprctl dispatch exec "$WVKBD_BIN -L 300 -H 350"
    echo "visible" > "$STATE_FILE"
    send_notify "Virtual Keyboard" "Shown"
else
    # Running -> Toggle visibility
    CURRENT_STATE="visible"
    [ -f "$STATE_FILE" ] && CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "visible")

    if [ "$CURRENT_STATE" = "visible" ]; then
        pkill -SIGUSR1 wvkbd-mobintl
        echo "hidden" > "$STATE_FILE"
        send_notify "Virtual Keyboard" "Hidden"
    else
        pkill -SIGUSR2 wvkbd-mobintl
        echo "visible" > "$STATE_FILE"
        send_notify "Virtual Keyboard" "Shown"
    fi
fi
