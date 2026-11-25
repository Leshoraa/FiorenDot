#!/usr/bin/env bash

# Map rot8 ORIENTATION directly to Hyprland transform (0, 1, 2, 3) to avoid query lag
case "$ORIENTATION" in
    "normal")
        TRANSFORM=0
        ;;
    "270")
        TRANSFORM=1
        ;;
    "inverted")
        TRANSFORM=2
        ;;
    "90")
        TRANSFORM=3
        ;;
    *)
        # Fallback when invoked manually without ORIENTATION set
        sleep 0.1
        TRANSFORM=$(hyprctl monitors -j | jq -r '.[] | select(.name=="eDP-1") | .transform')
        ;;
esac

echo "[$(date)] ORIENTATION=$ORIENTATION -> Set TRANSFORM=$TRANSFORM" >> /tmp/touchrotate.log

if [ -n "$TRANSFORM" ]; then
    # Sync touchscreen & stylus transform
    hyprctl eval "hl.config({ input = { touchdevice = { transform = $TRANSFORM }, tablet = { transform = $TRANSFORM } } }); hl.device({ name = 'wdht1f01:00-2575:0911', transform = $TRANSFORM }); hl.device({ name = 'wdht1f01:00-2575:0911-stylus', transform = $TRANSFORM })" >> /tmp/touchrotate.log 2>&1

    # Virtual Keyboard (wvkbd)
    WVKBD_BIN="$HOME/.local/bin/wvkbd-mobintl"
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
    STATE_FILE="$STATE_DIR/virtual_keyboard_tablet_mode"

    IS_ENABLED=true
    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "disabled" ]; then
        IS_ENABLED=false
    fi

    V_STATE="${XDG_RUNTIME_DIR:-/tmp}/wvkbd_visible"
    if [ "$TRANSFORM" -ne 0 ]; then
        # Tablet / rotated mode: show only if enabled
        if [ "$IS_ENABLED" = true ]; then
            if pgrep -x wvkbd-mobintl >/dev/null; then
                pkill -SIGUSR2 wvkbd-mobintl
            else
                hyprctl eval "hl.exec_cmd('$WVKBD_BIN -L 300 -H 350')" >/dev/null
            fi
            echo 1 > "$V_STATE"
        else
            # Keep hidden when disabled
            pkill -SIGUSR1 wvkbd-mobintl 2>/dev/null || true
            echo 0 > "$V_STATE"
        fi
    else
        # Laptop mode: always hide virtual keyboard
        pkill -SIGUSR1 wvkbd-mobintl 2>/dev/null || true
        echo 0 > "$V_STATE"
    fi
fi
