#!/usr/bin/env bash
# FiorenDot - Wayscriber Screen Drawing Helper (Native Wayland Layer)
# Author: Fioren (@Leshoraa)

ACTION="${1:-toggle}"

if ! command -v wayscriber >/dev/null 2>&1; then
    notify-send -u critical -i "dialog-warning" \
        "Wayscriber Missing" \
        "Install via terminal: yay -S wayscriber-bin" \
        -a "Wayscriber"
    exit 1
fi

case "$ACTION" in
    toggle)
        if ! pgrep -x wayscriber >/dev/null; then
            wayscriber --daemon --no-tray &
            sleep 0.25
        fi
        wayscriber --daemon-toggle
        ;;
    passthrough)
        if pgrep -x wayscriber >/dev/null; then
            wayscriber --light-toggle
            notify-send -u low \
                -h string:x-canonical-private-synchronous:wayscriber \
                -a "Wayscriber" \
                "Click-Through Toggled" \
                "Drawing passthrough mode changed"
        fi
        ;;
    quit)
        pkill -x wayscriber 2>/dev/null || true
        notify-send -u low \
            -h string:x-canonical-private-synchronous:wayscriber \
            -a "Wayscriber" \
            "Screen Drawing Closed"
        ;;
    *)
        echo "Usage: $0 {toggle|passthrough|quit}"
        exit 1
        ;;
esac
