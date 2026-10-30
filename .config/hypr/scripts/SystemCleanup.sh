#!/usr/bin/env bash
set -e

echo "=============================================="
echo "    💫 FiorenDot System Maintenance & Cleanup 💫"
echo "=============================================="

# 1. Remove Debug Packages
DEBUG_PKGS=$(pacman -Qq | grep -- '-debug$' || true)
if [ -n "$DEBUG_PKGS" ]; then
    echo -e "\n[1/4] Menghapus paket debug sisa kompilasi AUR (~1 GB)..."
    echo "$DEBUG_PKGS"
    sudo pacman -Rns --noconfirm $DEBUG_PKGS
else
    echo -e "\n[1/4] Tidak ada paket debug yang ditemukan."
fi

# 2. Paccache
echo -e "\n[2/4] Membersihkan cache pacman (menyimpan 1 versi)..."
sudo paccache -r -k 1
sudo paccache -r -u -k 0

# 3. Journal logs vacuum
echo -e "\n[3/4] Membatasi log systemd journal ke 100MB..."
sudo journalctl --vacuum-size=100M

# 4. Libvirtd socket activation
echo -e "\n[4/4] Mengoptimalkan background service libvirtd..."
if systemctl is-active --quiet libvirtd; then
    sudo systemctl stop libvirtd
    sudo systemctl disable libvirtd
    sudo systemctl enable libvirtd.socket
    echo "libvirtd diubah ke socket-activated (hanya aktif saat dibutuhkan)."
fi

echo -e "\n=============================================="
echo "    ✅ Pembersihan Sistem Selesai!"
echo "=============================================="
echo ""
read -p "Tekan [Enter] untuk keluar..."
