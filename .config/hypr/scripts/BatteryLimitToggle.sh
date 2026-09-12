#!/usr/bin/env bash
# ==============================================================================
# BatteryLimitToggle.sh
# Toggle batas pengisian baterai (80% <-> 100%) untuk SwayNC & Daemon Auto-80%
# ==============================================================================

THRESHOLD_FILE="/sys/class/power_supply/BATT/charge_control_end_threshold"
AC_ONLINE_FILE="/sys/class/power_supply/ACAD/online"
BAT_STATUS_FILE="/sys/class/power_supply/BATT/status"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
TIMER_FILE="$CACHE_DIR/battery_limit_100_start"
THREE_HOURS=10800 # 3 jam = 10800 detik

get_threshold() {
    if [ -f "$THRESHOLD_FILE" ]; then
        cat "$THRESHOLD_FILE" 2>/dev/null || echo "100"
    else
        echo "100"
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

set_threshold() {
    local val="$1"
    if [ ! -f "$THRESHOLD_FILE" ]; then
        notify-send -u critical -a "Battery Manager" "Error" "Hardware tidak mendukung batas baterai ($THRESHOLD_FILE tidak ditemukan)."
        return 1
    fi

    # 1. Coba tulis langsung (jika permission sudah 0666)
    if echo "$val" > "$THRESHOLD_FILE" 2>/dev/null; then
        return 0
    fi

    # 2. Coba sudo tanpa password jika tersedia
    if sudo -n tee "$THRESHOLD_FILE" <<< "$val" >/dev/null 2>&1; then
        return 0
    fi

    # 3. Fallback ke pkexec (dialog GUI polkit jika permission belum 0666)
    if pkexec sh -c "echo $val > '$THRESHOLD_FILE' && chmod 0666 '$THRESHOLD_FILE'" 2>/dev/null; then
        return 0
    fi

    notify-send -u critical -a "Battery" "Battery Limit Error" "Root permission required"
    return 1
}

toggle() {
    local current
    current=$(get_threshold)

    if [ "$current" -eq 80 ]; then
        # Switch to 100%
        if set_threshold 100; then
            date +%s > "$TIMER_FILE"
            notify-send -a "Battery" "Battery Limit" "Set to 100% (auto 80% after 3h)"
        fi
    else
        # Switch to 80%
        if set_threshold 80; then
            rm -f "$TIMER_FILE"
            notify-send -a "Battery" "Battery Limit" "Set to 80%"
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

check_timer() {
    local current
    current=$(get_threshold)

    if [ "$current" -eq 100 ]; then
        if is_charger_plugged; then
            if [ ! -f "$TIMER_FILE" ]; then
                date +%s > "$TIMER_FILE"
            else
                local start_time now elapsed
                start_time=$(cat "$TIMER_FILE" 2>/dev/null || echo "")
                if [ -n "$start_time" ]; then
                    now=$(date +%s)
                    elapsed=$((now - start_time))
                    if [ "$elapsed" -ge "$THREE_HOURS" ]; then
                        if set_threshold 80; then
                            rm -f "$TIMER_FILE"
                            notify-send -a "Battery" "Battery Limit" "Reverted to 80% (charger connected for 3h)"
                            local is_open
                            is_open=$(busctl --user call org.erikreider.swaync /org/erikreider/swaync/cc org.erikreider.swaync.cc GetVisibility 2>/dev/null | awk '{print $2}')
                            if [ "$is_open" = "false" ]; then
                                swaync-client -R 2>/dev/null || true
                            fi
                        fi
                    fi
                else
                    date +%s > "$TIMER_FILE"
                fi
            fi
        else
            rm -f "$TIMER_FILE"
        fi
    else
        rm -f "$TIMER_FILE"
    fi
}

daemon_loop() {
    while true; do
        check_timer
        sleep 30
    done
}

case "$1" in
    toggle)
        toggle
        ;;
    status)
        status
        ;;
    check)
        check_timer
        ;;
    daemon)
        daemon_loop
        ;;
    80)
        set_threshold 80
        rm -f "$TIMER_FILE"
        swaync-client -R 2>/dev/null || true
        ;;
    100)
        set_threshold 100
        date +%s > "$TIMER_FILE"
        swaync-client -R 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {toggle|status|check|daemon|80|100}"
        exit 1
        ;;
esac
