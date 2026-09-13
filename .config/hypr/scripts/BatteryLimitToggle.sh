#!/usr/bin/env bash
# ==============================================================================
# BatteryLimitToggle.sh
# Smart Battery Management & Notification Daemon (MacBook-Style Optimized Charging)
# ==============================================================================

# Locate power supply interfaces dynamically
BAT_DIR="/sys/class/power_supply/BATT"
[ ! -d "$BAT_DIR" ] && BAT_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)

AC_DIR="/sys/class/power_supply/ACAD"
[ ! -d "$AC_DIR" ] && AC_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "AC*" 2>/dev/null | head -n 1)

THRESHOLD_FILE="$BAT_DIR/charge_control_end_threshold"
BAT_STATUS_FILE="$BAT_DIR/status"
BAT_CAPACITY_FILE="$BAT_DIR/capacity"
AC_ONLINE_FILE="$AC_DIR/online"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
TIMER_FILE="$CACHE_DIR/battery_limit_100_start"
PERSISTENT_FILE="$STATE_DIR/battery_charge_limit"
SYS_STATE_FILE="/etc/asus-battery-charge-threshold"
SOAK_SECONDS=3600 # 1 hour soak time after reaching 100%

# Send desktop notifications without icons in clean English
send_notify() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -u "$urgency" -i "" -a "Battery" "$title" "$msg"
}

get_threshold() {
    if [ -f "$THRESHOLD_FILE" ]; then
        cat "$THRESHOLD_FILE" 2>/dev/null || echo "100"
    else
        echo "100"
    fi
}

get_capacity() {
    if [ -f "$BAT_CAPACITY_FILE" ]; then
        cat "$BAT_CAPACITY_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_battery_status() {
    if [ -f "$BAT_STATUS_FILE" ]; then
        cat "$BAT_STATUS_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

is_charger_plugged() {
    local ac=0
    local st=""
    if [ -f "$AC_ONLINE_FILE" ]; then
        ac=$(cat "$AC_ONLINE_FILE" 2>/dev/null || echo "0")
    fi
    if [ -f "$BAT_STATUS_FILE" ]; then
        st=$(cat "$BAT_STATUS_FILE" 2>/dev/null || echo "")
    fi
    if [ "$ac" -eq 1 ] || [ "$st" = "Charging" ] || [ "$st" = "Full" ]; then
        return 0
    fi
    return 1
}

get_saved_limit() {
    local target=""
    if [ -f "$SYS_STATE_FILE" ] && [ -s "$SYS_STATE_FILE" ]; then
        target=$(cat "$SYS_STATE_FILE" 2>/dev/null || echo "")
    fi
    if [ -z "$target" ] && [ -f "$PERSISTENT_FILE" ] && [ -s "$PERSISTENT_FILE" ]; then
        target=$(cat "$PERSISTENT_FILE" 2>/dev/null || echo "")
    fi
    if [ "$target" != "80" ] && [ "$target" != "100" ]; then
        target="80"
    fi
    echo "$target"
}

save_limit_state() {
    local val="$1"
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    echo "$val" > "$PERSISTENT_FILE" 2>/dev/null || true
    if [ -w "$SYS_STATE_FILE" ]; then
        echo "$val" > "$SYS_STATE_FILE" 2>/dev/null || true
    fi
}

set_threshold() {
    local val="$1"
    if [ ! -f "$THRESHOLD_FILE" ]; then
        send_notify "Battery Error" "Hardware does not support charge threshold." "critical"
        return 1
    fi

    # 1. Direct write (if permissions are 0666)
    if echo "$val" > "$THRESHOLD_FILE" 2>/dev/null; then
        save_limit_state "$val"
        return 0
    fi

    # 2. Sudo without password
    if sudo -n tee "$THRESHOLD_FILE" <<< "$val" >/dev/null 2>&1; then
        save_limit_state "$val"
        return 0
    fi

    # 3. Fallback to pkexec
    if pkexec sh -c "echo $val > '$THRESHOLD_FILE' && chmod 0666 '$THRESHOLD_FILE'" 2>/dev/null; then
        save_limit_state "$val"
        return 0
    fi

    send_notify "Battery Error" "Root permission required." "critical"
    return 1
}

toggle() {
    local current
    current=$(get_threshold)

    if [ "$current" -eq 80 ]; then
        # Switch to 100%
        if set_threshold 100; then
            rm -f "$TIMER_FILE"
            send_notify "Charge Limit" "Limit set to 100%."
            swaync-client -R 2>/dev/null || true
        fi
    else
        # Switch to 80%
        if set_threshold 80; then
            rm -f "$TIMER_FILE"
            send_notify "Charge Limit" "Limit set to 80%."
            swaync-client -R 2>/dev/null || true
        fi
    fi
}

status() {
    local current
    current=$(get_threshold)

    # 80%: active (true), 100%: inactive (false)
    if [ "$current" -eq 80 ]; then
        echo "true"
    else
        echo "false"
    fi
}

restore() {
    local target
    target=$(get_saved_limit)
    local current
    current=$(get_threshold)
    if [ "$current" -ne "$target" ]; then
        set_threshold "$target"
    fi
}

# Daemon loop: Monitors battery status, handles plug/unplug, low battery, and limit timers
daemon_loop() {
    restore

    local prev_ac=""
    local notified_low=false
    local notified_crit=false
    local notified_limit=false

    # Initial AC status reading
    if is_charger_plugged; then
        prev_ac=1
        local cap
        cap=$(get_capacity)
        local thresh
        thresh=$(get_threshold)
        if [ "$cap" -ge "$thresh" ]; then
            notified_limit=true
        fi
    else
        prev_ac=0
    fi

    while true; do
        local current_ac=0
        if is_charger_plugged; then
            current_ac=1
        fi

        local cap
        cap=$(get_capacity)
        local thresh
        thresh=$(get_threshold)
        local saved_target
        saved_target=$(get_saved_limit)

        # 1. AC Plug / Unplug Transition Detection
        if [ -n "$prev_ac" ] && [ "$current_ac" -ne "$prev_ac" ]; then
            if [ "$current_ac" -eq 1 ]; then
                # Charger connected
                if [ "$cap" -ge "$thresh" ]; then
                    send_notify "Charging Paused" "Battery at limit (${cap}%)."
                    notified_limit=true
                else
                    send_notify "Charging" "Battery is charging (${cap}%)."
                    notified_limit=false
                fi
                notified_low=false
                notified_crit=false
            else
                # Charger disconnected
                send_notify "Discharging" "Running on battery (${cap}%)."
                notified_limit=false
                # Auto revert 100% override to 80% on unplug to protect battery health
                rm -f "$TIMER_FILE"
                if [ "$thresh" -ne 80 ]; then
                    set_threshold 80
                    swaync-client -R 2>/dev/null || true
                fi
            fi
            prev_ac="$current_ac"
        fi

        # 2. Low Battery Warning while discharging
        if [ "$current_ac" -eq 0 ]; then
            if [ "$cap" -le 5 ] && [ "$notified_crit" = false ]; then
                send_notify "Critical Battery" "Battery is at ${cap}%. Connect charger now." "critical"
                notified_crit=true
                notified_low=true
            elif [ "$cap" -lt 15 ] && [ "$notified_low" = false ]; then
                send_notify "Low Battery" "Battery is below 15% (${cap}% remaining)." "critical"
                notified_low=true
            elif [ "$cap" -ge 20 ]; then
                notified_low=false
                notified_crit=false
            fi
        else
            # Reset low battery state when battery level recovers
            if [ "$cap" -ge 20 ]; then
                notified_low=false
                notified_crit=false
            fi
        fi

        # 3. Charging Limit Reached Notification
        if [ "$current_ac" -eq 1 ]; then
            if [ "$cap" -ge "$thresh" ] && [ "$notified_limit" = false ]; then
                send_notify "Charge Limit Reached" "Battery reached ${thresh}%."
                notified_limit=true
            elif [ "$cap" -lt "$((thresh - 4))" ]; then
                notified_limit=false
            fi
        fi

        # 4. Enforce Hardware Threshold (countering ASUS EC firmware resets after sleep/resume)
        if [ ! -f "$TIMER_FILE" ]; then
            if [ "$thresh" -ne "$saved_target" ]; then
                set_threshold "$saved_target"
            fi
        fi

        # 5. Timer for 100% Full Charge Override (soak timer starts AFTER reaching 100%)
        if [ "$thresh" -eq 100 ]; then
            if [ "$current_ac" -eq 1 ]; then
                local st
                st=$(get_battery_status)
                if [ "$cap" -ge 100 ] || [ "$st" = "Full" ]; then
                    if [ ! -f "$TIMER_FILE" ]; then
                        date +%s > "$TIMER_FILE"
                        send_notify "Battery Full" "Battery reached 100% (auto 80% in 1h)."
                    else
                        local start_time now elapsed
                        start_time=$(cat "$TIMER_FILE" 2>/dev/null || echo "")
                        if [ -n "$start_time" ]; then
                            now=$(date +%s)
                            elapsed=$((now - start_time))
                            if [ "$elapsed" -ge "$SOAK_SECONDS" ]; then
                                if set_threshold 80; then
                                    rm -f "$TIMER_FILE"
                                    send_notify "Charge Limit" "Limit restored to 80%."
                                    swaync-client -R 2>/dev/null || true
                                fi
                            fi
                        else
                            date +%s > "$TIMER_FILE"
                        fi
                    fi
                fi
            else
                rm -f "$TIMER_FILE"
                set_threshold 80
                swaync-client -R 2>/dev/null || true
            fi
        fi

        sleep 2
    done
}

case "$1" in
    toggle)
        toggle
        ;;
    status)
        status
        ;;
    restore)
        restore
        ;;
    daemon)
        daemon_loop
        ;;
    80)
        set_threshold 80
        rm -f "$TIMER_FILE"
        send_notify "Charge Limit" "Limit set to 80%."
        swaync-client -R 2>/dev/null || true
        ;;
    100)
        set_threshold 100
        rm -f "$TIMER_FILE"
        send_notify "Charge Limit" "Limit set to 100%."
        swaync-client -R 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {toggle|status|restore|daemon|80|100}"
        exit 1
        ;;
esac
