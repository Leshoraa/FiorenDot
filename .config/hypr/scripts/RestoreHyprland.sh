#!/usr/bin/env bash
set -e
echo "================================================="
echo "  🔄 Memulihkan Hyprland ke 0.56.2 & Config Asli"
echo "================================================="

echo -e "\n[1/3] Menghapus hyprland.lua default template..."
rm -f "$HOME/.config/hypr/hyprland.lua"

echo -e "\n[2/3] Mengembalikan paket Hyprland ke 0.56.2 dari cache..."
sudo pacman -U --noconfirm /var/cache/pacman/pkg/hyprland-0.56.2-3-x86_64.pkg.tar.zst

echo -e "\n[3/3] Mengunci Hyprland di pacman.conf agar aman..."
if grep -q "^IgnorePkg" /etc/pacman.conf; then
    if ! grep -q "hyprland" /etc/pacman.conf; then
        sudo sed -i '/^IgnorePkg/ s/$/ hyprland/' /etc/pacman.conf
    fi
else
    sudo sed -i 's/^#IgnorePkg.*=/IgnorePkg = hyprland/' /etc/pacman.conf
fi

echo -e "\n================================================="
echo "  ✅ Pemulihan Selesai! Reloading Hyprland..."
echo "================================================="
hyprctl reload || true
