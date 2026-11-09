#!/usr/bin/env bash
# FiorenDot - Gromit-MPX Screen Drawing Helper
# Author: Fioren (@Leshoraa)

ACTION="${1:-toggle}"

if ! command -v gromit-mpx >/dev/null 2>&1; then
    notify-send -u critical -i "dialog-warning" \
        "Gromit-MPX Missing" \
        "Install via terminal:\nyay -S gromit-mpx" \
        -a "Gromit-MPX"
    exit 1
fi

case "$ACTION" in
    toggle)
        if pidof gromit-mpx >/dev/null; then
            gromit-mpx --toggle
            notify-send -u low \
                -h string:x-canonical-private-synchronous:gromit \
                -a "Gromit-MPX" \
                "✏️ Screen Drawing" \
                "Toggled annotation mode"
        else
            gromit-mpx --active &
            notify-send -u low \
                -h string:x-canonical-private-synchronous:gromit \
                -a "Gromit-MPX" \
                "✏️ Screen Drawing Active" \
                "Draw with mouse/stylus • Super+Shift+C to clear"
        fi
        ;;
    clear)
        if pidof gromit-mpx >/dev/null; then
            gromit-mpx --clear
            notify-send -u low \
                -h string:x-canonical-private-synchronous:gromit \
                -a "Gromit-MPX" \
                "🧹 Annotations Cleared" \
                "All screen drawings removed"
        fi
        ;;
    undo)
        if pidof gromit-mpx >/dev/null; then
            gromit-mpx --undo
        fi
        ;;
    redo)
        if pidof gromit-mpx >/dev/null; then
            gromit-mpx --redo
        fi
        ;;
    quit)
        if pidof gromit-mpx >/dev/null; then
            gromit-mpx --quit
            notify-send -u low \
                -h string:x-canonical-private-synchronous:gromit \
                -a "Gromit-MPX" \
                "Screen Drawing Closed"
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|clear|undo|redo|quit}"
        exit 1
        ;;
esac
