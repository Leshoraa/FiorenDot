#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

PROCESS="hypridle"

sync_swaync() {
    # If triggered from outside SwayNC (e.g. keyboard shortcut or Waybar), reload SwayNC to update toggle button state
    if [[ -z "${SWAYNC_TOGGLE_STATE:-}" ]]; then
        (sleep 0.1 && swaync-client -R 2>/dev/null) &
    fi
}

cmd_on() {
    if ! pgrep -x "$PROCESS" >/dev/null; then
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch exec "$PROCESS" >/dev/null 2>&1
        else
            nohup "$PROCESS" >/dev/null 2>&1 &
        fi
    fi
    notify-send -e -u low -h string:x-canonical-private-synchronous:hypridle -h boolean:SWAYNC_BYPASS_DND:true "Hypridle" "Active"
    sync_swaync
}

cmd_off() {
    if pgrep -x "$PROCESS" >/dev/null; then
        pkill -x "$PROCESS"
    fi
    notify-send -e -u low -h string:x-canonical-private-synchronous:hypridle -h boolean:SWAYNC_BYPASS_DND:true "Hypridle" "Deactivated"
    sync_swaync
}

case "$1" in
    status)
        if pgrep -x "$PROCESS" >/dev/null; then
            echo '{"text": " ", "class": "deactivated", "tooltip": "Hypridle Active"}'
        else
            echo '{"text": " ", "class": "activated", "tooltip": "Hypridle Deactive"}'
        fi
        ;;
    on)
        cmd_on
        ;;
    off)
        cmd_off
        ;;
    toggle)
        if pgrep -x "$PROCESS" >/dev/null; then
            cmd_off
        else
            cmd_on
        fi
        ;;
    *)
        echo "Usage: $0 {status|toggle|on|off}"
        exit 1
        ;;
esac