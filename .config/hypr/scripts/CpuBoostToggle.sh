#!/usr/bin/env bash
# ==============================================================================
# CpuBoostToggle.sh
# Manages AMD Core Performance Boost (CPB / Turbo Boost) on-the-fly
# ==============================================================================

BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"

if [ ! -f "$BOOST_FILE" ]; then
    echo "Error: sysfs boost file not found ($BOOST_FILE)." >&2
    exit 1
fi

PREF_FILE="/etc/cpu_boost_battery_pref"
USER_PREF_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/cpu_boost_battery_pref"

save_battery_pref() {
    local val="$1"
    echo "$val" > "$PREF_FILE" 2>/dev/null || true
    mkdir -p "$(dirname "$USER_PREF_FILE")" 2>/dev/null || true
    echo "$val" > "$USER_PREF_FILE" 2>/dev/null || true
}

get_boost_status() {
    cat "$BOOST_FILE" 2>/dev/null || echo "unknown"
}

get_ac_status() {
    local ac
    ac=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo "1")
    if [ "$ac" -eq 1 ]; then
        echo "AC"
    else
        echo "Battery"
    fi
}

send_notification() {
    local desc="$1"
    local icon="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -e -u normal -h string:x-canonical-private-synchronous:cpuboost -h boolean:SWAYNC_BYPASS_DND:true -i "$icon" "CPU Turbo Boost" "$desc"
    fi
}

case "${1:-status}" in
    status)
        STATUS=$(get_boost_status)
        AC=$(get_ac_status)
        PREF=$(cat "$PREF_FILE" 2>/dev/null || cat "$USER_PREF_FILE" 2>/dev/null || echo "0")
        echo "============================================================"
        echo "  AMD CPU Turbo Boost (Core Performance Boost) Status"
        echo "============================================================"
        echo "  Power Source       : $AC"
        if [ "$STATUS" = "1" ]; then
            echo "  Current Boost      : ON (up to 4.25 GHz)"
        elif [ "$STATUS" = "0" ]; then
            echo "  Current Boost      : OFF (capped at 3.30 GHz base)"
        else
            echo "  Current Boost      : Unknown ($STATUS)"
        fi
        if [ "$PREF" = "1" ]; then
            echo "  Battery Preference : ON (keep boost on battery)"
        else
            echo "  Battery Preference : OFF (power-saving on battery)"
        fi
        echo ""
        echo "  Per-Core Clock:"
        grep "cpu MHz" /proc/cpuinfo | awk '{printf "    Core %2d: %7.2f MHz\n", NR-1, $4}'
        echo "============================================================"
        ;;

    on)
        if echo 1 > "$BOOST_FILE" 2>/dev/null; then
            save_battery_pref 1
            echo "CPU Turbo Boost: ON (up to 4.25 GHz)"
            send_notification "ON (max 4.25 GHz)" "speedometer"
        else
            echo "Error: failed to enable boost (check permissions / chmod 0666)." >&2
            exit 1
        fi
        ;;

    off)
        if echo 0 > "$BOOST_FILE" 2>/dev/null; then
            save_battery_pref 0
            echo "CPU Turbo Boost: OFF (capped at 3.30 GHz)"
            send_notification "OFF (max 3.30 GHz)" "battery-low"
        else
            echo "Error: failed to disable boost (check permissions / chmod 0666)." >&2
            exit 1
        fi
        ;;

    toggle)
        CUR=$(get_boost_status)
        if [ "$CUR" = "1" ]; then
            "$0" off
        else
            "$0" on
        fi
        ;;

    *)
        echo "Usage: $0 {status|on|off|toggle}" >&2
        exit 1
        ;;
esac
