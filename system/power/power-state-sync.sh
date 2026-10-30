#!/usr/bin/env bash
# ==============================================================================
# power-state-sync.sh
# Dynamic power state synchronization for AC / Battery transitions
# ==============================================================================

PREF_FILE="/etc/cpu_boost_battery_pref"
LAST_AC_FILE="/tmp/power_state_last_ac"
BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"
AC_FILE="/sys/class/power_supply/ACAD/online"

# Pastikan izin sysfs boost tetap terbuka untuk user biasa
if [ -f "$BOOST_FILE" ]; then
    chmod 0666 "$BOOST_FILE" 2>/dev/null || true
fi

# Pastikan file preferensi ada dan memiliki izin tulis non-root
if [ ! -f "$PREF_FILE" ]; then
    echo "0" > "$PREF_FILE"
fi
chmod 0666 "$PREF_FILE" 2>/dev/null || true

AC_ONLINE=$(cat "$AC_FILE" 2>/dev/null || echo "1")
LAST_AC=$(cat "$LAST_AC_FILE" 2>/dev/null || echo "")

if [ "$AC_ONLINE" -eq 1 ]; then
    # KONDISI: CHARGER DICOLOK (AC POWER)
    # Jika transisi dari baterai (LAST_AC == 0), simpan status boost baterai sebelum dipaksa aktif
    if [ "$LAST_AC" = "0" ] && [ -f "$BOOST_FILE" ]; then
        CUR_BOOST=$(cat "$BOOST_FILE" 2>/dev/null || echo "0")
        echo "$CUR_BOOST" > "$PREF_FILE"
        chmod 0666 "$PREF_FILE" 2>/dev/null || true
    fi

    # Selalu aktifkan turbo boost saat terhubung ke charger (AC)
    if [ -f "$BOOST_FILE" ]; then
        echo 1 > "$BOOST_FILE" 2>/dev/null || true
    fi

    # NVMe writeback normal di AC
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=500 vm.laptop_mode=0 >/dev/null 2>&1 || true

    echo "1" > "$LAST_AC_FILE"
    chmod 0666 "$LAST_AC_FILE" 2>/dev/null || true
else
    # KONDISI: CHARGER DICABUT (BATERAI)
    # Pulihkan status boost sesuai kondisi sebelum dicolok charger
    BAT_PREF=$(cat "$PREF_FILE" 2>/dev/null || echo "0")
    if [ "$BAT_PREF" != "1" ]; then
        BAT_PREF="0"
    fi

    if [ -f "$BOOST_FILE" ]; then
        echo "$BAT_PREF" > "$BOOST_FILE" 2>/dev/null || true
    fi

    # NVMe writeback hemat daya di baterai
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=1500 vm.laptop_mode=5 >/dev/null 2>&1 || true

    echo "0" > "$LAST_AC_FILE"
    chmod 0666 "$LAST_AC_FILE" 2>/dev/null || true
fi
