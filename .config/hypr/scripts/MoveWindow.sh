#!/usr/bin/env bash
# /* ---- 💫 FiorenDot / Hyprland Move Window Dispatcher 💫 ---- */
# Fast path for Floating windows (continuous glide with binded)
# Full smart sequence path for Tiled windows

dir="${1:-r}"

# Fast path: If active window is floating, move active window directly (takes ~6ms)
if hyprctl activewindow -j | grep -q '"floating": true'; then
    case "$dir" in
        l) hyprctl dispatch moveactive -40 0 ;;
        r) hyprctl dispatch moveactive 40 0 ;;
        u) hyprctl dispatch moveactive 0 -30 ;;
        d) hyprctl dispatch moveactive 0 30 ;;
    esac
    exit 0
fi

# Tiled window: delegate to SmartMoveWindow.py
exec python3 "$HOME/.config/hypr/scripts/SmartMoveWindow.py" "$dir"
