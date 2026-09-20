#!/usr/bin/env bash
# FiorenDot - Pin Floating Window
# Author: Fioren (@Leshoraa)
# Pins/Unpins active floating window so it stays visible across all workspaces

notif_img="$HOME/.config/swaync/images"

TARGET_ADDR=""
AUTO_FLOAT=false

for arg in "$@"; do
    if [ "$arg" = "--auto-float" ]; then
        AUTO_FLOAT=true
    elif [[ "$arg" =~ ^(address:)?0x[0-9a-fA-F]+$ ]]; then
        TARGET_ADDR="${arg#address:}"
    fi
done

if [ -n "$TARGET_ADDR" ]; then
    ACTIVE_WIN=$(hyprctl clients -j 2>/dev/null | jq -r --arg a "$TARGET_ADDR" '.[] | select(.address == $a or .address == ("0x" + $a))' 2>/dev/null)
else
    ACTIVE_WIN=$(hyprctl activewindow -j 2>/dev/null)
fi

# If no window found, exit quietly
if [ -z "$ACTIVE_WIN" ] || [ "$ACTIVE_WIN" = "{}" ] || [ "$ACTIVE_WIN" = "null" ]; then
    exit 0
fi

ADDR=$(echo "$ACTIVE_WIN" | jq -r '.address // empty')
IS_FLOATING=$(echo "$ACTIVE_WIN" | jq -r '.floating // false')
IS_PINNED=$(echo "$ACTIVE_WIN" | jq -r '.pinned // false')
WIN_TITLE=$(echo "$ACTIVE_WIN" | jq -r '.title // "Window"')

if [ -z "$ADDR" ]; then
    exit 0
fi

# Truncate title if too long for clean notification
if [ ${#WIN_TITLE} -gt 35 ]; then
    WIN_TITLE="${WIN_TITLE:0:32}..."
fi

if [ "$IS_FLOATING" = "true" ]; then
    # Toggle pin using Hyprland's native dispatcher
    hyprctl dispatch pin "address:$ADDR"
    
    if [ "$IS_PINNED" = "true" ]; then
        notify-send -u low -i "$notif_img/note.png" \
            -h string:x-canonical-private-synchronous:hypr-pin \
            -a "Hyprland" \
            "Window Unpinned" \
            "$WIN_TITLE"
    else
        notify-send -u low -i "$notif_img/ja.png" \
            -h string:x-canonical-private-synchronous:hypr-pin \
            -a "Hyprland" \
            "Window Pinned" \
            "$WIN_TITLE"
    fi
else
    if [ "$AUTO_FLOAT" = true ]; then
        # Float first then pin
        hyprctl dispatch togglefloating "address:$ADDR"
        sleep 0.05
        hyprctl dispatch pin "address:$ADDR"
        notify-send -u low -i "$notif_img/ja.png" \
            -h string:x-canonical-private-synchronous:hypr-pin \
            -a "Hyprland" \
            "Window Pinned" \
            "$WIN_TITLE"
    else
        notify-send -u normal -i "$notif_img/error.png" \
            -h string:x-canonical-private-synchronous:hypr-pin \
            -a "Hyprland" \
            "Window Not Floating" \
            "Enable floating first"
    fi
fi
