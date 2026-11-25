#!/usr/bin/env bash
# /* ---- 💫 FiorenDot / Hyprland Move Window Dispatcher 💫 ---- */
# Fast path for Floating windows (continuous glide with binded)
# Full smart sequence path for Tiled windows

dir="${1:-r}"

# Fast path: If active window is floating, move active window directly (takes ~6ms)
if hyprctl activewindow -j | grep -q '"floating": true'; then
    case "$dir" in
        l) hyprctl eval 'hl.dispatch(hl.dsp.window.move({ x = -40, y = 0, relative = true }))' >/dev/null ;;
        r) hyprctl eval 'hl.dispatch(hl.dsp.window.move({ x = 40, y = 0, relative = true }))' >/dev/null ;;
        u) hyprctl eval 'hl.dispatch(hl.dsp.window.move({ x = 0, y = -30, relative = true }))' >/dev/null ;;
        d) hyprctl eval 'hl.dispatch(hl.dsp.window.move({ x = 0, y = 30, relative = true }))' >/dev/null ;;
    esac
    exit 0
fi

# Tiled window: delegate to SmartMoveWindow.py
exec python3 "$HOME/.config/hypr/scripts/SmartMoveWindow.py" "$dir"
