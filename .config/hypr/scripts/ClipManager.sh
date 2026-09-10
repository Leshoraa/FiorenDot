#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager with Native Realtime Image Preview.
# This script uses cliphist, rofi, and wl-copy.

# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
feed_script="$HOME/.config/hypr/scripts/ClipFeed.py"

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

while true; do
    result=$(
        rofi -i -dmenu \
            -show-icons \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -config "$rofi_theme" < <("$feed_script") 
    )
    status=$?

    case "$status" in
        1)
            # ESC or closed
            exit 0
            ;;
        0)
            # Enter pressed -> decode & copy to clipboard
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit 0
                    ;;
            esac
            ;;
        10)
            # Control-Delete -> delete entry
            cliphist delete <<<"$result"
            if [[ "$result" =~ ^([0-9]+)[[:space:]] ]]; then
                rm -f "$HOME/.cache/cliphist_thumbs/${BASH_REMATCH[1]}_square.png"
            fi
            ;;
        11)
            # Alt-Delete -> wipe clipboard
            cliphist wipe
            rm -rf "$HOME/.cache/cliphist_thumbs"/*
            ;;
    esac
done
