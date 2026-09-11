#!/usr/bin/env bash
# waydroid-start: Start Waydroid with specified resolution & orientation
# Usage:
#   waydroid-start         -> Normal Landscape (1920x1200)
#   waydroid-start 90      -> Portrait (1200x1920)
#   waydroid-start 180     -> Inverted Landscape (1920x1200)
#   waydroid-start 270     -> Reverse Portrait (1200x1920)

set -e

# Pastikan direktori state ada agar tidak terjadi crash user_migration di Waydroid
mkdir -p "$HOME/.local/state/waydroid" "$HOME/.local/share/applications"

ARG="${1:-normal}"

case "$ARG" in
    90|"portrait")
        WIDTH=1200
        HEIGHT=1920
        ROT=0
        MODE_NAME="Portrait (90° - 1200x1920)"
        ;;
    180|"inverted")
        WIDTH=1920
        HEIGHT=1200
        ROT=2
        MODE_NAME="Inverted Landscape (180° - 1920x1200)"
        ;;
    270|"reverse-portrait")
        WIDTH=1200
        HEIGHT=1920
        ROT=2
        MODE_NAME="Reverse Portrait (270° - 1200x1920)"
        ;;
    0|"normal"|"landscape"|*)
        WIDTH=1920
        HEIGHT=1200
        ROT=0
        MODE_NAME="Normal Landscape (0° - 1920x1200)"
        ;;
esac

echo "========================================="
echo " Starting Waydroid: $MODE_NAME"
echo "========================================="

# 1. Hentikan sesi yang sedang berjalan jika ada
if waydroid status 2>/dev/null | grep -q "RUNNING"; then
    echo "Menghentikan sesi Waydroid aktif..."
    waydroid session stop 2>/dev/null || true
    sleep 1
fi

# 2. Atur resolusi sesuai mode
echo "Mengatur resolusi Waydroid ke ${WIDTH}x${HEIGHT}..."
sudo waydroid prop set persist.waydroid.width "$WIDTH"
sudo waydroid prop set persist.waydroid.height "$HEIGHT"

# 3. Restart container agar resolusi baru dibaca
echo "Memuat ulang service Waydroid..."
sudo systemctl restart waydroid-container.service

# 4. Jalankan Full UI
echo "Membuka Waydroid Full UI..."
waydroid show-full-ui &

# 5. Atur rotasi jika mode inverted
if [ "$ROT" -ne 0 ]; then
    (
        for i in {1..10}; do
            sleep 1
            if waydroid status 2>/dev/null | grep -q "RUNNING"; then
                sudo waydroid shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
                sudo waydroid shell settings put system user_rotation "$ROT" >/dev/null 2>&1 || true
                break
            fi
        done
    ) &
fi

echo "Waydroid berhasil dijalankan ($MODE_NAME)!"
