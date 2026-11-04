#!/usr/bin/env bash
# ==============================================================================
# /usr/lib/systemd/system-sleep/battery-limit-rtc.sh
# Systemd sleep hook for Battery Limit RTC Auto-Wake & Auto-Resuspend
# ==============================================================================

ACTION="$1"
PHASE="$2"

BAT_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)
AC_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "AC*" 2>/dev/null | head -n 1)
RTC_ALARM="/sys/class/rtc/rtc0/wakealarm"
TARGET_FILE="/run/battery_rtc_wake_target"
SYS_STATE="/etc/asus-battery-charge-threshold"
USER_STATE="/home/fioren/.local/state/battery_charge_limit"
USER_OVERRIDE="/home/fioren/.cache/battery_override_start"
USER_TIMER="/home/fioren/.cache/battery_limit_100_start"

is_ac_online() {
    [ -n "$AC_DIR" ] && [ -f "$AC_DIR/online" ] && [ "$(cat "$AC_DIR/online" 2>/dev/null)" -eq 1 ]
}

get_threshold() {
    if [ -n "$BAT_DIR" ] && [ -f "$BAT_DIR/charge_control_end_threshold" ]; then
        cat "$BAT_DIR/charge_control_end_threshold" 2>/dev/null || echo "100"
    else
        echo "100"
    fi
}

set_80() {
    if [ -n "$BAT_DIR" ] && [ -f "$BAT_DIR/charge_control_end_threshold" ]; then
        echo 80 > "$BAT_DIR/charge_control_end_threshold" 2>/dev/null || true
    fi
    echo 80 > "$SYS_STATE" 2>/dev/null || true
    echo 80 > "$USER_STATE" 2>/dev/null || true
    rm -f "$USER_OVERRIDE" "$USER_TIMER" "$TARGET_FILE" 2>/dev/null || true
    if [ -f "$RTC_ALARM" ]; then
        echo 0 > "$RTC_ALARM" 2>/dev/null || true
    fi
}

is_lid_closed() {
    grep -qi "closed" /proc/acpi/button/lid/*/state 2>/dev/null
}

case "$ACTION" in
    pre)
        # Clear any old target file
        rm -f "$TARGET_FILE" 2>/dev/null || true

        # Only set RTC alarm if plugged in to AC and threshold is 100
        if is_ac_online && [ "$(get_threshold)" -ge 100 ]; then
            NOW=$(date +%s)
            WAKE_SECS=5400 # Default: 1.5 hours (90 minutes)

            # If an override was started recently, calculate remaining time until 2 hours
            if [ -f "$USER_OVERRIDE" ]; then
                O_START=$(cat "$USER_OVERRIDE" 2>/dev/null || echo "")
                if [ -n "$O_START" ]; then
                    ELAPSED=$((NOW - O_START))
                    REMAINING=$((7200 - ELAPSED))
                    if [ "$REMAINING" -gt 1800 ] && [ "$REMAINING" -le 7200 ]; then
                        WAKE_SECS=$REMAINING
                    elif [ "$REMAINING" -le 1800 ]; then
                        WAKE_SECS=1800
                    fi
                fi
            fi

            # Set hardware RTC alarm
            if [ -f "$RTC_ALARM" ]; then
                echo 0 > "$RTC_ALARM" 2>/dev/null || true
                echo "+$WAKE_SECS" > "$RTC_ALARM" 2>/dev/null || true
                TARGET_TIME=$((NOW + WAKE_SECS))
                echo "$TARGET_TIME" > "$TARGET_FILE" 2>/dev/null || true
            fi
        fi
        ;;

    post)
        if [ -f "$TARGET_FILE" ]; then
            TARGET_TIME=$(cat "$TARGET_FILE" 2>/dev/null || echo "0")
            NOW=$(date +%s)
            rm -f "$TARGET_FILE" 2>/dev/null || true

            # If wake time has arrived (within tolerance window of target)
            if [ "$NOW" -ge $((TARGET_TIME - 120)) ]; then
                # Revert threshold to 80%
                set_80

                # If lid is STILL closed, this was an automated RTC background wake!
                # Re-suspend immediately after current suspend service finishes deactivating.
                if is_lid_closed; then
                    (
                        sleep 4
                        if is_lid_closed; then
                            systemctl suspend
                        fi
                    ) >/dev/null 2>&1 &
                fi
            else
                # Woken early by user (power button / lid open before alarm fired)
                # Clear alarm so it doesn't fire unexpectedly while in use
                if [ -f "$RTC_ALARM" ]; then
                    echo 0 > "$RTC_ALARM" 2>/dev/null || true
                fi
            fi
        fi
        ;;
esac

exit 0
