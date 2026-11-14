#!/usr/bin/env bash
# FiorenDot - Wayscriber Screen Drawing Helper (Native Wayland Layer)
# Author: Fioren (@Leshoraa)

ACTION="${1:-toggle}"

case "$ACTION" in
    toggle)
        if ! pgrep -x wayscriber >/dev/null; then
            systemctl --user start wayscriber.service 2>/dev/null || wayscriber --daemon --no-tray &
            sleep 0.2
        fi
        wayscriber --daemon-toggle
        ;;
    passthrough)
        wayscriber --light-toggle
        ;;
    quit)
        systemctl --user stop wayscriber.service 2>/dev/null || pkill -x wayscriber 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {toggle|passthrough|quit}"
        exit 1
        ;;
esac
