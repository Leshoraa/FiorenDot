#!/usr/bin/env bash
# ==============================================================================
# Script Optimasi Linux (Performa & Baterai) - ASUS Vivobook (AMD Ryzen 5 5600H)
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Script ini memerlukan hak akses root (sudo)."
    echo "Silakan jalankan: sudo bash $0"
    exit 1
fi

echo "🚀 [1/6] Membersihkan modul legacy acpi_cpufreq..."
rm -f /etc/modules-load.d/acpi-cpufreq.conf
echo "  ✓ Modul kernel disiapkan untuk native amd_pstate."

echo "🔧 [2/6] Mengonfigurasi parameter boot loader (systemd-boot)..."
for conf in /boot/loader/entries/*.conf; do
    if [ -f "$conf" ]; then
        cp "$conf" "${conf}.bak"
        # Bersihkan parameter lama jika ada
        sed -i 's/ amd_pstate\.shared_mem=1//g' "$conf"
        sed -i 's/ amd_pstate=disable//g' "$conf"
        sed -i 's/ amd_pstate=active//g' "$conf"
        sed -i 's/ acpi_osi="!Processor Device"//g' "$conf"

        # Aktifkan driver modern AMD P-State (EPP / Autonomous Mode)
        sed -i '/^options/ s/$/ amd_pstate=active/' "$conf"
        echo "  ✓ Diperbarui: $conf (backup disimpan di ${conf}.bak)"
    fi
done

echo "🧹 [3/6] Menonaktifkan service background yang tidak diperlukan..."
if systemctl is-enabled supergfxd.service &>/dev/null; then
    systemctl disable --now supergfxd.service || true
    echo "  ✓ supergfxd.service dinonaktifkan."
else
    echo "  - supergfxd.service sudah nonaktif."
fi

if systemctl is-enabled libvirtd.service &>/dev/null; then
    systemctl disable libvirtd.service || true
    echo "  ✓ libvirtd.service dinonaktifkan dari autostart."
fi

if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
    systemctl disable NetworkManager-wait-online.service || true
    echo "  ✓ NetworkManager-wait-online.service dinonaktifkan."
fi

echo "🔋 [4/6] Mengonfigurasi Battery Health Charging Limit (80%) & Izin Akses Tombol..."
if [ -f /sys/class/power_supply/BATT/charge_control_end_threshold ]; then
    echo 80 > /sys/class/power_supply/BATT/charge_control_end_threshold || true
    chmod 0666 /sys/class/power_supply/BATT/charge_control_end_threshold || true

    cat << 'EOF' > /etc/systemd/system/asus-battery-charge-threshold.service
[Unit]
Description=Set ASUS Battery Charge Threshold to 80% and allow user control
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/sh -c 'echo 80 > /sys/class/power_supply/BATT/charge_control_end_threshold && chmod 0666 /sys/class/power_supply/BATT/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
EOF

    # Udev rule agar charge_control_end_threshold selalu bisa diubah oleh tombol SwayNC tanpa password
    cat << 'EOF' > /etc/udev/rules.d/99-battery-charge-threshold.rules
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}!="", RUN+="/bin/chmod 0666 /sys%p/charge_control_end_threshold"
EOF

    systemctl daemon-reload
    systemctl enable --now asus-battery-charge-threshold.service
    udevadm control --reload-rules && udevadm trigger --subsystem-match=power_supply || true
    echo "  ✓ Batas charge 80% aktif & izin kontrol non-root berhasil diatur."
else
    echo "  - Hardware tidak mendukung charge_control_end_threshold."
fi

echo "🧠 [5/6] Mengoptimalkan ZRAM (Multitasking Satset)..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
echo "  ✓ ZRAM dikonfigurasi ke 50% RAM (~7.5GB) dengan kompresi cepat zstd."

echo "⚡ [6/6] Mengaktifkan PCIe ASPM & Runtime Power Management..."
cat << 'EOF' > /etc/udev/rules.d/99-powersave.rules
# Audio power save
ACTION=="add", SUBSYSTEM=="module", KERNEL=="snd_hda_intel", ATTR{parameters/power_save}="10"
ACTION=="add", SUBSYSTEM=="module", KERNEL=="snd_hda_intel", ATTR{parameters/power_save_controller}="Y"

# PCIe ASPM powersave policy
ACTION=="add", SUBSYSTEM=="module", KERNEL=="pcie_aspm", ATTR{parameters/policy}="powersave"

# Runtime PM for PCI devices
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
EOF

if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
    echo powersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
fi

echo ""
echo "======================================================================"
echo "✨ SEMUA OPTIMASI SISTEM SELESAI DITERAPKAN!"
echo "======================================================================"
echo "Pemeriksaan driver CPU saat ini:"
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]; then
    echo "Driver: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)"
    echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
else
    echo "Driver cpufreq akan aktif penuh setelah sistem di-reboot."
fi
echo "Batas charge baterai: $(cat /sys/class/power_supply/BATT/charge_control_end_threshold 2>/dev/null || echo 'N/A')%"
echo "======================================================================"
