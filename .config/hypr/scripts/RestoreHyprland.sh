#!/usr/bin/env bash
set -e
echo "================================================="
echo "  Restoring Hyprland 0.56.2 & original config"
echo "================================================="

echo -e "\n[1/3] Removing hyprland.lua..."
rm -f "$HOME/.config/hypr/hyprland.lua"

echo -e "\n[2/3] Downgrading Hyprland to 0.56.2 from pacman cache..."
sudo pacman -U --noconfirm /var/cache/pacman/pkg/hyprland-0.56.2-3-x86_64.pkg.tar.zst

echo -e "\n[3/3] Pinning Hyprland in /etc/pacman.conf..."
if grep -q "^IgnorePkg" /etc/pacman.conf; then
    if ! grep -q "hyprland" /etc/pacman.conf; then
        sudo sed -i '/^IgnorePkg/ s/$/ hyprland/' /etc/pacman.conf
    fi
else
    sudo sed -i 's/^#IgnorePkg.*=/IgnorePkg = hyprland/' /etc/pacman.conf
fi

echo -e "\n================================================="
echo "  Restore complete. Reloading Hyprland..."
echo "================================================="
hyprctl reload || true
