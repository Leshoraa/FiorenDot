#!/usr/bin/env bash
# ==============================================================================
# SetupPowerOptimizations.sh
# Configures dynamic CPU Turbo Boost (Stateful) & NVMe Flush Optimization
# ==============================================================================
set -e

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo "============================================================"
echo "  ⚡ Menerapkan Optimasi Daya CPU Boost (Stateful) & NVMe ⚡"
echo "============================================================"

SYNC_SCRIPT="/usr/local/bin/power-state-sync.sh"
RULES_FILE="/etc/udev/rules.d/99-powersave.rules"
PREF_FILE="/etc/cpu_boost_battery_pref"

echo -e "\n[1/5] Memasang script sinkronisasi daya ke $SYNC_SCRIPT..."
$SUDO bash -c "cat << 'SYNC' > $SYNC_SCRIPT
#!/usr/bin/env bash
# ==============================================================================
# power-state-sync.sh
# Dynamic power state synchronization for AC / Battery transitions
# ==============================================================================

PREF_FILE=\"/etc/cpu_boost_battery_pref\"
LAST_AC_FILE=\"/tmp/power_state_last_ac\"
BOOST_FILE=\"/sys/devices/system/cpu/cpufreq/boost\"
AC_FILE=\"/sys/class/power_supply/ACAD/online\"

# Pastikan izin sysfs boost tetap terbuka untuk user biasa
if [ -f \"\$BOOST_FILE\" ]; then
    chmod 0666 \"\$BOOST_FILE\" 2>/dev/null || true
fi

# Pastikan file preferensi ada dan memiliki izin tulis non-root
if [ ! -f \"\$PREF_FILE\" ]; then
    echo \"0\" > \"\$PREF_FILE\"
fi
chmod 0666 \"\$PREF_FILE\" 2>/dev/null || true

AC_ONLINE=\$(cat \"\$AC_FILE\" 2>/dev/null || echo \"1\")
LAST_AC=\$(cat \"\$LAST_AC_FILE\" 2>/dev/null || echo \"\")

if [ \"\$AC_ONLINE\" -eq 1 ]; then
    # KONDISI: CHARGER DICOLOK (AC POWER)
    # Jika transisi dari baterai (LAST_AC == 0), simpan status boost baterai sebelum dipaksa aktif
    if [ \"\$LAST_AC\" = \"0\" ] && [ -f \"\$BOOST_FILE\" ]; then
        CUR_BOOST=\$(cat \"\$BOOST_FILE\" 2>/dev/null || echo \"0\")
        echo \"\$CUR_BOOST\" > \"\$PREF_FILE\"
        chmod 0666 \"\$PREF_FILE\" 2>/dev/null || true
    fi

    # Selalu aktifkan turbo boost saat terhubung ke charger (AC)
    if [ -f \"\$BOOST_FILE\" ]; then
        echo 1 > \"\$BOOST_FILE\" 2>/dev/null || true
    fi

    # NVMe writeback normal di AC
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=500 vm.laptop_mode=0 >/dev/null 2>&1 || true

    echo \"1\" > \"\$LAST_AC_FILE\"
    chmod 0666 \"\$LAST_AC_FILE\" 2>/dev/null || true
else
    # KONDISI: CHARGER DICABUT (BATERAI)
    # Pulihkan status boost sesuai kondisi sebelum dicolok charger
    BAT_PREF=\$(cat \"\$PREF_FILE\" 2>/dev/null || echo \"0\")
    if [ \"\$BAT_PREF\" != \"1\" ]; then
        BAT_PREF=\"0\"
    fi

    if [ -f \"\$BOOST_FILE\" ]; then
        echo \"\$BAT_PREF\" > \"\$BOOST_FILE\" 2>/dev/null || true
    fi

    # NVMe writeback hemat daya di baterai
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=1500 vm.laptop_mode=5 >/dev/null 2>&1 || true

    echo \"0\" > \"\$LAST_AC_FILE\"
    chmod 0666 \"\$LAST_AC_FILE\" 2>/dev/null || true
fi
SYNC"

$SUDO chmod 755 "$SYNC_SCRIPT"
echo "  ✓ $SYNC_SCRIPT berhasil dibuat dan diberi izin eksekusi."

echo -e "\n[2/5] Menyiapkan file state $PREF_FILE..."
if [ ! -f "$PREF_FILE" ]; then
    $SUDO bash -c "echo '0' > $PREF_FILE"
fi
$SUDO chmod 0666 "$PREF_FILE"
echo "  ✓ $PREF_FILE siap digunakan."

echo -e "\n[3/5] Menulis aturan udev ke $RULES_FILE..."
$SUDO bash -c "cat << 'RULES' > $RULES_FILE
# Audio power save
ACTION==\"add\", SUBSYSTEM==\"module\", KERNEL==\"snd_hda_intel\", ATTR{parameters/power_save}=\"10\"
ACTION==\"add\", SUBSYSTEM==\"module\", KERNEL==\"snd_hda_intel\", ATTR{parameters/power_save_controller}=\"Y\"

# PCIe ASPM powersave policy
ACTION==\"add\", SUBSYSTEM==\"module\", KERNEL==\"pcie_aspm\", ATTR{parameters/policy}=\"powersave\"

# Runtime PM for PCI devices
ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{power/control}=\"auto\"

# Ensure CPU boost sysfs permission allows non-root user control
SUBSYSTEM==\"cpu\", RUN+=\"/usr/bin/chmod 0666 /sys/devices/system/cpu/cpufreq/boost\"

# Dynamic CPU Turbo Boost and NVMe Disk Flush Sleep Optimization on Battery vs AC
SUBSYSTEM==\"power_supply\", KERNEL==\"ACAD\", RUN+=\"/usr/local/bin/power-state-sync.sh\"
RULES"
echo "  ✓ Aturan udev berhasil disimpan."

echo -e "\n[4/5] Memuat ulang aturan udev (udevadm reload)..."
$SUDO udevadm control --reload-rules

echo -e "\n[5/5] Menjalankan sinkronisasi status daya saat ini..."
$SUDO "$SYNC_SCRIPT"

echo -e "\n============================================================"
echo "  ✅ OPTIMASI DAYA STATEFUL BERHASIL AKTIF!"
echo "============================================================"
echo "Status Saat Ini:"
echo "  - Power Source         : $(cat /sys/class/power_supply/ACAD/online | grep -q 1 && echo 'AC Power' || echo 'Battery')"
echo "  - CPU Boost Value      : $(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)"
echo "  - Battery Saved Pref   : $(cat /etc/cpu_boost_battery_pref 2>/dev/null)"
echo "  - Sysctl Dirty centisec: $(sysctl -n vm.dirty_writeback_centisecs)"
echo "  - Sysctl Laptop mode   : $(sysctl -n vm.laptop_mode)"
echo "============================================================"
