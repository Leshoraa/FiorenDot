#!/usr/bin/env bash

# ZoomDesktop.sh - Smooth desktop viewport zooming for Hyprland (ala vxwm)
ACTION="${1:-reset}"
STEP="${2:-1.25}"

CURRENT=$(hyprctl getoption cursor:zoom_factor 2>/dev/null | awk 'NR==1 {print $2}')
if [ -z "$CURRENT" ]; then
    CURRENT=1.0
fi

case "$ACTION" in
    in)
        NEW=$(awk -v c="$CURRENT" -v s="$STEP" 'BEGIN {
            val = c * s;
            if (val >= 0.96 && val <= 1.04) val = 1.0;
            printf "%.2f", val;
        }')
        hyprctl keyword cursor:zoom_factor "$NEW"
        ;;
    out)
        NEW=$(awk -v c="$CURRENT" -v s="$STEP" 'BEGIN {
            val = c / s;
            if (val < 1.0) val = 1.0;
            if (val >= 0.96 && val <= 1.04) val = 1.0;
            printf "%.2f", val;
        }')
        hyprctl keyword cursor:zoom_factor "$NEW"
        ;;
    toggle)
        NEW=$(awk -v c="$CURRENT" 'BEGIN {
            if (c > 1.05) printf "1.0";
            else printf "1.5";
        }')
        hyprctl keyword cursor:zoom_factor "$NEW"
        ;;
    reset)
        hyprctl keyword cursor:zoom_factor 1.0
        ;;
    set)
        TARGET="${2:-2.0}"
        hyprctl keyword cursor:zoom_factor "$TARGET"
        ;;
    *)
        echo "Usage: $0 [in|out|toggle|reset|set] [step/target]"
        ;;
esac
