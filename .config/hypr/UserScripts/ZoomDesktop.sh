#!/usr/bin/env bash

# ZoomDesktop.sh - Smooth desktop viewport zooming for Hyprland (ala vxwm)
ACTION="${1:-reset}"

CURRENT=$(hyprctl getoption cursor:zoom_factor 2>/dev/null | awk 'NR==1 {print $2}')
if [ -z "$CURRENT" ]; then
    CURRENT=1.0
fi

case "$ACTION" in
    in)
        NEW=$(awk -v c="$CURRENT" 'BEGIN {
            val = c * 1.15;
            if (val > 3.0) val = 3.0;
            if (val >= 0.96 && val <= 1.04) val = 1.0;
            printf "%.2f", val;
        }')
        hyprctl keyword cursor:zoom_factor "$NEW"
        ;;
    out)
        NEW=$(awk -v c="$CURRENT" 'BEGIN {
            val = c / 1.15;
            if (val < 0.5) val = 0.5;
            if (val >= 0.96 && val <= 1.04) val = 1.0;
            printf "%.2f", val;
        }')
        hyprctl keyword cursor:zoom_factor "$NEW"
        ;;
    reset)
        hyprctl keyword cursor:zoom_factor 1.0
        ;;
    *)
        echo "Usage: $0 [in|out|reset]"
        ;;
esac
