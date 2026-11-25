#!/usr/bin/env bash
# ==============================================================================
# power-state-sync.sh
# Dynamic power state synchronization for AC / Battery transitions
# ==============================================================================

PREF_FILE="/etc/cpu_boost_battery_pref"
LAST_AC_FILE="/tmp/power_state_last_ac"
BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"
AC_FILE="/sys/class/power_supply/ACAD/online"

# Keep sysfs boost writable by non-root users
if [ -f "$BOOST_FILE" ]; then
    chmod 0666 "$BOOST_FILE" 2>/dev/null || true
fi

# Ensure battery boost preference file exists and is user-writable
if [ ! -f "$PREF_FILE" ]; then
    echo "0" > "$PREF_FILE"
fi
chmod 0666 "$PREF_FILE" 2>/dev/null || true

AC_ONLINE=$(cat "$AC_FILE" 2>/dev/null || echo "1")
LAST_AC=$(cat "$LAST_AC_FILE" 2>/dev/null || echo "")

if [ "$AC_ONLINE" -eq 1 ]; then
    # AC connected: snapshot battery boost pref on battery -> AC transition
    if [ "$LAST_AC" = "0" ] && [ -f "$BOOST_FILE" ]; then
        CUR_BOOST=$(cat "$BOOST_FILE" 2>/dev/null || echo "0")
        echo "$CUR_BOOST" > "$PREF_FILE"
        chmod 0666 "$PREF_FILE" 2>/dev/null || true
    fi

    # Always enable boost on AC
    if [ -f "$BOOST_FILE" ]; then
        echo 1 > "$BOOST_FILE" 2>/dev/null || true
    fi

    # Standard NVMe writeback on AC
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=500 vm.laptop_mode=0 >/dev/null 2>&1 || true

    echo "1" > "$LAST_AC_FILE"
    chmod 0666 "$LAST_AC_FILE" 2>/dev/null || true
else
    # Battery: restore saved battery boost preference
    BAT_PREF=$(cat "$PREF_FILE" 2>/dev/null || echo "0")
    if [ "$BAT_PREF" != "1" ]; then
        BAT_PREF="0"
    fi

    if [ -f "$BOOST_FILE" ]; then
        echo "$BAT_PREF" > "$BOOST_FILE" 2>/dev/null || true
    fi

    # Power-saving NVMe writeback on battery
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=1500 vm.laptop_mode=5 >/dev/null 2>&1 || true

    echo "0" > "$LAST_AC_FILE"
    chmod 0666 "$LAST_AC_FILE" 2>/dev/null || true
fi
