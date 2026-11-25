#!/usr/bin/env bash
# ==============================================================================
# Linux Performance & Battery Tuning - ASUS Vivobook (AMD Ryzen 5 5600H)
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: root privileges required. Run: sudo bash $0" >&2
    exit 1
fi

echo "[1/7] Building ACPI override to neutralize OpenCore CPU duplicate in Linux..."
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
echo "  ✓ Created /boot/acpi_override.img."

echo "[2/7] Removing legacy acpi_cpufreq autoload..."
rm -f /etc/modules-load.d/acpi-cpufreq.conf
echo "  ✓ Ready for native amd_pstate."

echo "[3/7] Updating systemd-boot entries..."
for conf in /boot/loader/entries/*.conf; do
    if [ -f "$conf" ]; then
        cp "$conf" "${conf}.bak"
        # Strip legacy pstate/OSI flags
        sed -i 's/ amd_pstate\.shared_mem=1//g' "$conf"
        sed -i 's/ amd_pstate=disable//g' "$conf"
        sed -i 's/ amd_pstate=active//g' "$conf"
        sed -i 's/ acpi_osi="!Processor Device"//g' "$conf"

        # Load acpi_override.img before initramfs
        if ! grep -q "acpi_override.img" "$conf"; then
            sed -i '/initrd.*initramfs/i initrd  /acpi_override.img' "$conf"
        fi
        if [ -f /boot/amd-ucode.img ] && ! grep -q "amd-ucode.img" "$conf"; then
            sed -i '/initrd.*initramfs/i initrd  /amd-ucode.img' "$conf"
        fi

        # Enable AMD P-State active (EPP)
        sed -i '/^options/ s/$/ amd_pstate=active/' "$conf"
        echo "  ✓ Updated $conf (backup: ${conf}.bak)"
    fi
done

echo "[4/7] Registering systemd-boot with UEFI NVRAM..."
bootctl install || true
echo "  ✓ Bootloader registered."

echo "[5/7] Disabling unneeded background services..."
if systemctl is-enabled supergfxd.service &>/dev/null; then
    systemctl disable --now supergfxd.service || true
    echo "  ✓ Disabled supergfxd.service."
else
    echo "  - supergfxd.service already disabled."
fi

if systemctl is-enabled libvirtd.service &>/dev/null; then
    systemctl disable libvirtd.service || true
    echo "  ✓ Disabled libvirtd.service autostart."
fi

if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
    systemctl disable NetworkManager-wait-online.service || true
    echo "  ✓ Disabled NetworkManager-wait-online.service."
fi

echo "[6/7] Configuring battery charge threshold & user sysfs permissions..."
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
ExecStart=/bin/sh -c 'chmod 0666 /sys/class/power_supply/BATT/charge_control_end_threshold; touch /etc/asus-battery-charge-threshold && chmod 0666 /etc/asus-battery-charge-threshold; if [ -s /etc/asus-battery-charge-threshold ]; then cat /etc/asus-battery-charge-threshold > /sys/class/power_supply/BATT/charge_control_end_threshold; else echo 80 > /sys/class/power_supply/BATT/charge_control_end_threshold; fi'

[Install]
WantedBy=multi-user.target
EOF

    # Allow passwordless threshold updates from SwayNC/user scripts
    cat << 'EOF' > /etc/udev/rules.d/99-battery-charge-threshold.rules
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}!="", RUN+="/bin/chmod 0666 /sys%p/charge_control_end_threshold"
EOF

    systemctl daemon-reload
    systemctl enable --now asus-battery-charge-threshold.service
    udevadm control --reload-rules && udevadm trigger --subsystem-match=power_supply || true
    echo "  ✓ Charge threshold persisted & non-root control enabled."
else
    echo "  - Hardware does not expose charge_control_end_threshold."
fi

echo "[7/7] Configuring ZRAM & powersave udev rules..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
echo "  ✓ ZRAM set to 50% RAM with zstd."

# AMD P-State EPP Rule (Balance Performance)
cat << 'EOF' > /etc/udev/rules.d/50-amd-epp.rules
ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}!="", ATTR{cpufreq/energy_performance_preference}="balance_performance"
EOF
echo "  ✓ Configured AMD P-State EPP (balance_performance)."

# PCIe ASPM powersave policy
cat << 'EOF' > /etc/udev/rules.d/99-powersave.rules
# Audio power save
ACTION=="add", SUBSYSTEM=="module", KERNEL=="snd_hda_intel", ATTR{parameters/power_save}="10"
ACTION=="add", SUBSYSTEM=="module", KERNEL=="snd_hda_intel", ATTR{parameters/power_save_controller}="Y"

# PCIe ASPM powersave policy
ACTION=="add", SUBSYSTEM=="module", KERNEL=="pcie_aspm", ATTR{parameters/policy}="powersave"

# Runtime PM for PCI devices
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"

# Ensure CPU boost sysfs permission allows non-root user control
SUBSYSTEM=="cpu", RUN+="/usr/bin/chmod 0666 /sys/devices/system/cpu/cpufreq/boost"

# Dynamic CPU Turbo Boost and NVMe Disk Flush Sleep Optimization on Battery vs AC
SUBSYSTEM=="power_supply", KERNEL=="ACAD", RUN+="/usr/local/bin/power-state-sync.sh"
EOF

if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
    echo powersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
fi

# Apply EPP immediately if active
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
    echo "balance_performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null 2>&1 || true
fi

echo ""
echo "======================================================================"
echo "System optimizations applied."
echo "======================================================================"
echo "CPU scaling state:"
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]; then
    echo "Driver: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)"
    echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    echo "EPP Preference: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo 'N/A')"
else
    echo "cpufreq driver will activate on reboot."
fi
echo "Battery charge threshold: $(cat /sys/class/power_supply/BATT/charge_control_end_threshold 2>/dev/null || echo 'N/A')%"
echo "======================================================================"
