#!/usr/bin/env bash
# ==============================================================================
# CpuBoostToggle.sh
# Manages AMD Core Performance Boost (CPB / Turbo Boost) on-the-fly
# ==============================================================================

BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"

if [ ! -f "$BOOST_FILE" ]; then
    echo "❌ Error: Sysfs boost file tidak ditemukan ($BOOST_FILE)."
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
        echo "AC Power (Charger)"
    else
        echo "Battery (Baterai)"
    fi
}

send_notification() {
    local desc="$1"
    local icon="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -e -u low -h string:x-canonical-private-synchronous:cpuboost -i "$icon" "CPU Turbo Boost" "$desc"
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
            echo "  Current Boost      : AKTIF (Hingga 4.25 GHz)"
        elif [ "$STATUS" = "0" ]; then
            echo "  Current Boost      : NONAKTIF (Capped di Base Clock 3.30 GHz)"
        else
            echo "  Current Boost      : Tidak diketahui ($STATUS)"
        fi
        if [ "$PREF" = "1" ]; then
            echo "  Battery Preference : AKTIF (Tetap Boost saat charger dicabut)"
        else
            echo "  Battery Preference : NONAKTIF (Hemat daya saat charger dicabut)"
        fi
        echo ""
        echo "  Frekuensi Real-Time Tiap Core:"
        grep "cpu MHz" /proc/cpuinfo | awk '{printf "    Core %2d: %7.2f MHz\n", NR-1, $4}'
        echo "============================================================"
        ;;

    on)
        if echo 1 > "$BOOST_FILE" 2>/dev/null; then
            save_battery_pref 1
            echo "✓ CPU Turbo Boost berhasil DIAKTIFKAN (Hingga 4.25 GHz)."
            send_notification "Aktif (Maks 4.25 GHz)" "speedometer"
        else
            echo "❌ Gagal mengaktifkan boost. Periksa izin akses (butuh root atau chmod 0666)."
            exit 1
        fi
        ;;

    off)
        if echo 0 > "$BOOST_FILE" 2>/dev/null; then
            save_battery_pref 0
            echo "✓ CPU Turbo Boost berhasil DINONAKTIFKAN (Capped di 3.30 GHz)."
            send_notification "Nonaktif (Maks 3.30 GHz)" "battery-low"
        else
            echo "❌ Gagal menonaktifkan boost. Periksa izin akses (butuh root atau chmod 0666)."
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
        echo "Penggunaan: $0 {status|on|off|toggle}"
        exit 1
        ;;
esac
