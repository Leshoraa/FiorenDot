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
echo "  Stateful CPU Boost & NVMe Power Optimization Setup"
echo "============================================================"

SYNC_SCRIPT="/usr/local/bin/power-state-sync.sh"
RULES_FILE="/etc/udev/rules.d/99-powersave.rules"
PREF_FILE="/etc/cpu_boost_battery_pref"

echo -e "\n[1/5] Installing power-state sync script to $SYNC_SCRIPT..."
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

# Keep sysfs boost writable by non-root users
if [ -f \"\$BOOST_FILE\" ]; then
    chmod 0666 \"\$BOOST_FILE\" 2>/dev/null || true
fi

# Ensure battery boost preference file exists and is user-writable
if [ ! -f \"\$PREF_FILE\" ]; then
    echo \"0\" > \"\$PREF_FILE\"
fi
chmod 0666 \"\$PREF_FILE\" 2>/dev/null || true

AC_ONLINE=\$(cat \"\$AC_FILE\" 2>/dev/null || echo \"1\")
LAST_AC=\$(cat \"\$LAST_AC_FILE\" 2>/dev/null || echo \"\")

if [ \"\$AC_ONLINE\" -eq 1 ]; then
    # AC connected: snapshot battery boost pref on battery -> AC transition
    if [ \"\$LAST_AC\" = \"0\" ] && [ -f \"\$BOOST_FILE\" ]; then
        CUR_BOOST=\$(cat \"\$BOOST_FILE\" 2>/dev/null || echo \"0\")
        echo \"\$CUR_BOOST\" > \"\$PREF_FILE\"
        chmod 0666 \"\$PREF_FILE\" 2>/dev/null || true
    fi

    # Always enable boost on AC
    if [ -f \"\$BOOST_FILE\" ]; then
        echo 1 > \"\$BOOST_FILE\" 2>/dev/null || true
    fi

    # Standard NVMe writeback on AC
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=500 vm.laptop_mode=0 >/dev/null 2>&1 || true

    echo \"1\" > \"\$LAST_AC_FILE\"
    chmod 0666 \"\$LAST_AC_FILE\" 2>/dev/null || true
else
    # Battery: restore saved battery boost preference
    BAT_PREF=\$(cat \"\$PREF_FILE\" 2>/dev/null || echo \"0\")
    if [ \"\$BAT_PREF\" != \"1\" ]; then
        BAT_PREF=\"0\"
    fi

    if [ -f \"\$BOOST_FILE\" ]; then
        echo \"\$BAT_PREF\" > \"\$BOOST_FILE\" 2>/dev/null || true
    fi

    # Power-saving NVMe writeback on battery
    /usr/bin/sysctl -w vm.dirty_writeback_centisecs=1500 vm.laptop_mode=5 >/dev/null 2>&1 || true

    echo \"0\" > \"\$LAST_AC_FILE\"
    chmod 0666 \"\$LAST_AC_FILE\" 2>/dev/null || true
fi
SYNC"

$SUDO chmod 755 "$SYNC_SCRIPT"
echo "  ✓ Installed $SYNC_SCRIPT."

echo -e "\n[2/5] Initializing $PREF_FILE..."
if [ ! -f "$PREF_FILE" ]; then
    $SUDO bash -c "echo '0' > $PREF_FILE"
fi
$SUDO chmod 0666 "$PREF_FILE"
echo "  ✓ Ready: $PREF_FILE."

echo -e "\n[3/5] Writing udev rules to $RULES_FILE..."
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
echo "  ✓ Saved udev rules."

echo -e "\n[4/5] Reloading udev rules..."
$SUDO udevadm control --reload-rules

echo -e "\n[5/5] Running initial power state sync..."
$SUDO "$SYNC_SCRIPT"

echo -e "\n============================================================"
echo "  Stateful power optimization active."
echo "============================================================"
echo "Current Status:"
echo "  - Power Source         : $(cat /sys/class/power_supply/ACAD/online | grep -q 1 && echo 'AC Power' || echo 'Battery')"
echo "  - CPU Boost Value      : $(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)"
echo "  - Battery Saved Pref   : $(cat /etc/cpu_boost_battery_pref 2>/dev/null)"
echo "  - Sysctl Dirty centisec: $(sysctl -n vm.dirty_writeback_centisecs)"
echo "  - Sysctl Laptop mode   : $(sysctl -n vm.laptop_mode)"
echo "============================================================"
