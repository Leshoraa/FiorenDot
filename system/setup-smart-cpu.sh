#!/bin/bash
# Setup AMD P-State Smart Scaling (balance_power)
# Allows CPU to drop to 413 MHz idle while boosting to 4.2 GHz on load,
# keeping fans silent and laptop cold while eliminating lag.

set -e

echo "Memasang AMD Smart EPP Service..."
sudo cp "$HOME/Projects/FiorenDot/system/amd-smart-epp.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now amd-smart-epp.service

echo ""
echo "Verifikasi status core CPU:"
for i in {0..3}; do
    echo -n "CPU $i EPP: "
    cat "/sys/devices/system/cpu/cpu$i/cpufreq/energy_performance_preference"
done

echo ""
echo "SUKSES! Mode pintar AMD sudah aktif permanen."
