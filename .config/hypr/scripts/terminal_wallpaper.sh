#!/bin/bash
# 1. Ambil path wallpaper aktif
WALL=$(swww query | awk -F 'image: ' '{print $2}' | head -n 1)
[ -z "$WALL" ] && WALL=$(hyprctl hyprpaper listactive | awk '{print $NF}' | head -n 1)

# 2. Keluar jika tidak ada wallpaper
[ ! -f "$WALL" ] && exit 1

# 3. Proses gambar ke /tmp dengan nama statis (agar ringan & gak nyampah)
# Kita pakai 300x300 agar rasio tetap aman dan ukuran kecil.
magick "$WALL" -resize 300x300 /tmp/terminal_logo.png
