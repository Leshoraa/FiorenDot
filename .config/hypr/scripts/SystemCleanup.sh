#!/usr/bin/env bash
set -e

echo "=============================================="
echo "      FiorenDot System Cleanup"
echo "=============================================="

# 1. Remove Debug Packages
DEBUG_PKGS=$(pacman -Qq | grep -- '-debug$' || true)
if [ -n "$DEBUG_PKGS" ]; then
    echo -e "\n[1/4] Removing AUR debug packages..."
    echo "$DEBUG_PKGS"
    sudo pacman -Rns --noconfirm $DEBUG_PKGS
else
    echo -e "\n[1/4] No debug packages found."
fi

# 2. Paccache
echo -e "\n[2/4] Cleaning pacman cache (keeping 1 version)..."
sudo paccache -r -k 1
sudo paccache -r -u -k 0

# 3. Journal logs vacuum
echo -e "\n[3/4] Vacuuming systemd journal to 100MB..."
sudo journalctl --vacuum-size=100M

# 4. Libvirtd socket activation
echo -e "\n[4/4] Switching libvirtd to socket activation..."
if systemctl is-active --quiet libvirtd; then
    sudo systemctl stop libvirtd
    sudo systemctl disable libvirtd
    sudo systemctl enable libvirtd.socket
    echo "libvirtd switched to socket activation."
fi

echo -e "\n=============================================="
echo "  Cleanup complete."
echo "=============================================="
echo ""
read -p "Press [Enter] to exit..."
