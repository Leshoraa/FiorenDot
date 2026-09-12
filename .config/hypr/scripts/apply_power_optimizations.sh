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

echo "🛡️  [1/7] Membuat ACPI Override untuk menetralkan duplikat CPU OpenCore di Linux..."
python3 -c "
import struct, os, subprocess

sig = b'SSDT'
length = 36
rev = 2
oemid = b'ZPSS\x00\x00'
oemtableid = b'CpuPlugA'
oemrev = 0x3001
creatorid = b'INTL'
creatorrev = 0x20260408

raw = struct.pack('<4sIBB6s8sI4sI', sig, length, rev, 0, oemid, oemtableid, oemrev, creatorid, creatorrev)
chk = (256 - (sum(raw) % 256)) % 256
raw = struct.pack('<4sIBB6s8sI4sI', sig, length, rev, chk, oemid, oemtableid, oemrev, creatorid, creatorrev)

build_dir = '/tmp/acpi_cpio_build'
os.makedirs(f'{build_dir}/kernel/firmware/acpi', exist_ok=True)
with open(f'{build_dir}/kernel/firmware/acpi/ssdt.aml', 'wb') as f:
    f.write(raw)

p = subprocess.run(['find', 'kernel'], cwd=build_dir, stdout=subprocess.PIPE)
p2 = subprocess.run(['cpio', '-H', 'newc', '--create'], cwd=build_dir, input=p.stdout, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
with open('/boot/acpi_override.img', 'wb') as f:
    f.write(p2.stdout)
"
echo "  ✓ /boot/acpi_override.img berhasil dibuat."

echo "🚀 [2/7] Membersihkan modul legacy acpi_cpufreq..."
rm -f /etc/modules-load.d/acpi-cpufreq.conf
echo "  ✓ Modul kernel disiapkan untuk native amd_pstate."

echo "🔧 [3/7] Mengonfigurasi parameter boot loader (systemd-boot)..."
for conf in /boot/loader/entries/*.conf; do
    if [ -f "$conf" ]; then
        cp "$conf" "${conf}.bak"
        # Bersihkan parameter lama jika ada
        sed -i 's/ amd_pstate\.shared_mem=1//g' "$conf"
        sed -i 's/ amd_pstate=disable//g' "$conf"
        sed -i 's/ amd_pstate=active//g' "$conf"
        sed -i 's/ acpi_osi="!Processor Device"//g' "$conf"

        # Pastikan acpi_override.img dimuat sebelum initramfs
        if ! grep -q "acpi_override.img" "$conf"; then
            sed -i '/initrd.*initramfs/i initrd  /acpi_override.img' "$conf"
        fi

        # Aktifkan driver modern AMD P-State (EPP / Autonomous Mode)
        sed -i '/^options/ s/$/ amd_pstate=active/' "$conf"
        echo "  ✓ Diperbarui: $conf (backup disimpan di ${conf}.bak)"
    fi
done

echo "📦 [4/7] Mendaftarkan Linux Boot Manager (systemd-boot) ke UEFI NVRAM..."
bootctl install || true
echo "  ✓ Bootloader Linux terdaftar di NVRAM."

echo "🧹 [5/7] Menonaktifkan service background yang tidak diperlukan..."
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

echo "🔋 [6/7] Mengonfigurasi Battery Health Charging Limit (Preserve State) & Izin Akses Tombol..."
if [ -f /sys/class/power_supply/BATT/charge_control_end_threshold ]; then
    chmod 0666 /sys/class/power_supply/BATT/charge_control_end_threshold || true
    touch /etc/asus-battery-charge-threshold && chmod 0666 /etc/asus-battery-charge-threshold || true

    cat << 'EOF' > /etc/systemd/system/asus-battery-charge-threshold.service
[Unit]
Description=Restore ASUS Battery Charge Threshold and allow user control
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/sh -c 'chmod 0666 /sys/class/power_supply/BATT/charge_control_end_threshold; touch /etc/asus-battery-charge-threshold && chmod 0666 /etc/asus-battery-charge-threshold; if [ -s /etc/asus-battery-charge-threshold ]; then cat /etc/asus-battery-charge-threshold > /sys/class/power_supply/BATT/charge_control_end_threshold; elif [ -s /home/fioren/.local/state/battery_charge_limit ]; then cat /home/fioren/.local/state/battery_charge_limit > /sys/class/power_supply/BATT/charge_control_end_threshold; else echo 80 > /sys/class/power_supply/BATT/charge_control_end_threshold; fi'

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
    echo "  ✓ Batas charge tersimpan & izin kontrol non-root berhasil diatur."
else
    echo "  - Hardware tidak mendukung charge_control_end_threshold."
fi

echo "🧠 [7/7] Mengoptimalkan ZRAM (Multitasking Satset)..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
echo "  ✓ ZRAM dikonfigurasi ke 50% RAM (~7.5GB) dengan kompresi cepat zstd."

# PCIe ASPM powersave policy
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
