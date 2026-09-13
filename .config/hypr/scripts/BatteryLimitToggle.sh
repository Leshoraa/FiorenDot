#!/usr/bin/env bash
# ==============================================================================
# BatteryLimitToggle.sh
# Toggle batas pengisian baterai (80% <-> 100%) untuk SwayNC & Daemon Auto-80%
# ==============================================================================

THRESHOLD_FILE="/sys/class/power_supply/BATT/charge_control_end_threshold"
AC_ONLINE_FILE="/sys/class/power_supply/ACAD/online"
BAT_STATUS_FILE="/sys/class/power_supply/BATT/status"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
TIMER_FILE="$CACHE_DIR/battery_limit_100_start"
PERSISTENT_FILE="$STATE_DIR/battery_charge_limit"
SYS_STATE_FILE="/etc/asus-battery-charge-threshold"
TIMEOUT_SECONDS=9000 # 2.5 jam = 9000 detik (2 jam 30 menit)

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
        notify-send -u critical -a "Battery Manager" "Error" "Hardware tidak mendukung batas baterai ($THRESHOLD_FILE tidak ditemukan)."
        return 1
    fi

    # 1. Coba tulis langsung (jika permission sudah 0666)
    if echo "$val" > "$THRESHOLD_FILE" 2>/dev/null; then
        save_limit_state "$val"
        return 0
    fi

    # 2. Coba sudo tanpa password jika tersedia
    if sudo -n tee "$THRESHOLD_FILE" <<< "$val" >/dev/null 2>&1; then
        save_limit_state "$val"
        return 0
    fi

    # 3. Fallback ke pkexec (dialog GUI polkit jika permission belum 0666)
    if pkexec sh -c "echo $val > '$THRESHOLD_FILE' && chmod 0666 '$THRESHOLD_FILE'" 2>/dev/null; then
        save_limit_state "$val"
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
            notify-send -a "Battery" "Battery Limit" "Set to 100% (auto 80% after 2.5h)"
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
                    if [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]; then
                        if set_threshold 80; then
                            rm -f "$TIMER_FILE"
                            notify-send -a "Battery" "Battery Limit" "Reverted to 80% (charger connected for 2.5h)"
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

restore() {
    local target=""
    if [ -f "$SYS_STATE_FILE" ] && [ -s "$SYS_STATE_FILE" ]; then
        target=$(cat "$SYS_STATE_FILE" 2>/dev/null || echo "")
    fi
    if [ -z "$target" ] && [ -f "$PERSISTENT_FILE" ] && [ -s "$PERSISTENT_FILE" ]; then
        target=$(cat "$PERSISTENT_FILE" 2>/dev/null || echo "")
    fi

    if [ "$target" != "80" ] && [ "$target" != "100" ]; then
        target=80
    fi

    local current
    current=$(get_threshold)
    if [ "$current" -ne "$target" ]; then
        set_threshold "$target"
    fi
}

daemon_loop() {
    restore
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
    restore)
        restore
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
        echo "Usage: $0 {toggle|status|check|restore|daemon|80|100}"
        exit 1
        ;;
esac
