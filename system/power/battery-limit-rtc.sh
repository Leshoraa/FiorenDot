#!/usr/bin/env bash
# ==============================================================================
# /usr/lib/systemd/system-sleep/battery-limit-rtc.sh
# Systemd sleep hook to preserve manual battery charge limit across suspend/resume
# ==============================================================================

ACTION="$1"

BAT_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)
RTC_ALARM="/sys/class/rtc/rtc0/wakealarm"
TARGET_FILE="/run/battery_rtc_wake_target"
SYS_STATE="/etc/asus-battery-charge-threshold"

get_saved_limit() {
    local val=""
    if [ -s "$SYS_STATE" ]; then
        val=$(cat "$SYS_STATE" 2>/dev/null || echo "")
    fi
    if [ "$val" != "80" ] && [ "$val" != "100" ]; then
        for u_home in /home/*; do
            if [ -s "$u_home/.local/state/battery_charge_limit" ]; then
                val=$(cat "$u_home/.local/state/battery_charge_limit" 2>/dev/null || echo "")
                break
            fi
        done
    fi
    if [ "$val" != "80" ] && [ "$val" != "100" ]; then
        val="80"
    fi
    echo "$val"
}

case "$ACTION" in
    pre)
        rm -f "$TARGET_FILE" 2>/dev/null || true
        if [ -f "$RTC_ALARM" ]; then
            echo 0 > "$RTC_ALARM" 2>/dev/null || true
        fi
        ;;

    post)
        rm -f "$TARGET_FILE" 2>/dev/null || true
        if [ -n "$BAT_DIR" ] && [ -f "$BAT_DIR/charge_control_end_threshold" ]; then
            SAVED=$(get_saved_limit)
            echo "$SAVED" > "$BAT_DIR/charge_control_end_threshold" 2>/dev/null || true
            chmod 0666 "$BAT_DIR/charge_control_end_threshold" 2>/dev/null || true
        fi
        ;;
esac

exit 0
