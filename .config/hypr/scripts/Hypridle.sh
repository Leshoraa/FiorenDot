#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

PROCESS="hypridle"
INHIBIT_TAG="HypridleToggle"

sync_swaync() {
    # If triggered from outside SwayNC (e.g. keyboard shortcut or Waybar), reload SwayNC to update toggle button state
    if [[ -z "${SWAYNC_TOGGLE_STATE:-}" ]]; then
        (sleep 0.1 && swaync-client -R 2>/dev/null) &
    fi
}

ensure_hypridle() {
    if ! pgrep -x "$PROCESS" >/dev/null; then
        systemctl --user start hypridle.service 2>/dev/null || {
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl dispatch exec "$PROCESS" >/dev/null 2>&1
            else
                nohup "$PROCESS" >/dev/null 2>&1 &
            fi
        }
    fi
}

is_inhibited() {
    pgrep -f "systemd-inhibit.*${INHIBIT_TAG}" >/dev/null
}

cmd_on() {
    # Remove idle inhibitor to restore normal idle timers
    pkill -f "systemd-inhibit.*${INHIBIT_TAG}" 2>/dev/null || true
    ensure_hypridle
    notify-send -e -u low -h string:x-canonical-private-synchronous:hypridle -h boolean:SWAYNC_BYPASS_DND:true "Hypridle" "Active"
    sync_swaync
}

cmd_off() {
    # Keep hypridle running for suspend lock, but inhibit idle timeouts (dim/lock)
    ensure_hypridle
    if ! is_inhibited; then
        nohup systemd-inhibit --what=idle --who="${INHIBIT_TAG}" --why="Manual idle toggle" sleep infinity >/dev/null 2>&1 &
    fi
    notify-send -e -u low -h string:x-canonical-private-synchronous:hypridle -h boolean:SWAYNC_BYPASS_DND:true "Hypridle" "Deactivated"
    sync_swaync
}

case "$1" in
    status)
        ensure_hypridle
        if is_inhibited; then
            echo '{"text": " ", "class": "activated", "tooltip": "Hypridle Inactive"}'
        else
            echo '{"text": " ", "class": "deactivated", "tooltip": "Hypridle Active"}'
        fi
        ;;
    on)
        cmd_on
        ;;
    off)
        cmd_off
        ;;
    toggle)
        if is_inhibited; then
            cmd_on
        else
            cmd_off
        fi
        ;;
    *)
        echo "Usage: $0 {status|toggle|on|off}"
        exit 1
        ;;
esac