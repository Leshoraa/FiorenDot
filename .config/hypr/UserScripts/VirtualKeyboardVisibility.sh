#!/usr/bin/env bash
# ==============================================================================
# VirtualKeyboardVisibility.sh
# Toggle wvkbd on-screen visibility (open/close) instantly via Wayland signals
# ==============================================================================

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/wvkbd_visible"
WVKBD_BIN="$HOME/.local/bin/wvkbd-mobintl"

if ! pgrep -x wvkbd-mobintl >/dev/null; then
    # Not running -> Launch it visible
    hyprctl dispatch exec "$WVKBD_BIN -L 300 -H 350"
    echo 1 > "$STATE_FILE"
else
    # Running -> Toggle visibility between show and hide
    IS_VIS=1
    [ -f "$STATE_FILE" ] && IS_VIS=$(cat "$STATE_FILE" 2>/dev/null || echo 1)

    if [ "$IS_VIS" -eq 1 ]; then
        pkill -SIGUSR1 wvkbd-mobintl
        echo 0 > "$STATE_FILE"
    else
        pkill -SIGUSR2 wvkbd-mobintl
        echo 1 > "$STATE_FILE"
    fi
fi
