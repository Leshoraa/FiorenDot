#!/bin/bash
# Setup AMD P-State Smart Scaling (balance_power)
# Allows CPU to drop to 413 MHz idle while boosting to 4.2 GHz on load,
# keeping fans silent and laptop cold while eliminating lag.

set -e

# Detect correct user home directory even when executed via sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"
SOURCE_FILE="$USER_HOME/Projects/FiorenDot/system/amd-smart-epp.service"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File $SOURCE_FILE tidak ditemukan!"
    exit 1
fi

echo "Memasang AMD Smart EPP Service..."
cp "$SOURCE_FILE" /etc/systemd/system/amd-smart-epp.service
systemctl daemon-reload
systemctl enable --now amd-smart-epp.service

echo ""
echo "Verifikasi status core CPU:"
for i in {0..3}; do
    echo -n "CPU $i EPP: "
    cat "/sys/devices/system/cpu/cpu$i/cpufreq/energy_performance_preference"
done

echo ""
echo "SUKSES! Mode pintar AMD (balance_power) sudah aktif permanen!"
