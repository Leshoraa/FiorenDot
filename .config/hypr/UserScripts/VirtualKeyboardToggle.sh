#!/usr/bin/env bash

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/virtual_keyboard_tablet_mode"
WVKBD_BIN="$HOME/.local/bin/wvkbd-mobintl"

mkdir -p "$STATE_DIR" 2>/dev/null || true

send_notify() {
    notify-send -u normal -i "" -h string:x-canonical-private-synchronous:vkeyboard -a "Virtual Keyboard" "$1" "$2"
}

# Determine current status (default is enabled)
IS_ENABLED=true
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "disabled" ]; then
    IS_ENABLED=false
fi

# Detect current screen orientation (0: normal laptop mode, != 0: tablet/tent mode)
TRANSFORM=$(hyprctl monitors -j | jq -r '.[] | select(.name=="eDP-1") | .transform' 2>/dev/null || echo 0)
V_STATE="${XDG_RUNTIME_DIR:-/tmp}/wvkbd_visible"

if [ "$IS_ENABLED" = true ]; then
    # Toggle to Disabled / Deactivated
    echo "disabled" > "$STATE_FILE"
    send_notify "Virtual Keyboard" "Tablet virtual keyboard disabled."

    # If currently running in tablet mode, hide it
    pkill -SIGUSR1 wvkbd-mobintl 2>/dev/null || true
    echo 0 > "$V_STATE"
else
    # Toggle to Enabled / Activated
    echo "enabled" > "$STATE_FILE"
    send_notify "Virtual Keyboard" "Tablet virtual keyboard enabled."

    # If currently in tablet mode, show the keyboard immediately
    if [ "$TRANSFORM" -ne 0 ]; then
        if pgrep -x wvkbd-mobintl >/dev/null; then
            pkill -SIGUSR2 wvkbd-mobintl
        else
            hyprctl dispatch exec "$WVKBD_BIN -L 300 -H 350"
        fi
        echo 1 > "$V_STATE"
    fi
fi
