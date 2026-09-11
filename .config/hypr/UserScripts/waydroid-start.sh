#!/usr/bin/env bash
# waydroid-start: Start Waydroid with specified resolution & orientation
# Usage:
#   waydroid-start         -> Normal Landscape (1920x1200)
#   waydroid-start 90      -> Portrait (1200x1920)
#   waydroid-start 180     -> Inverted Landscape (1920x1200)
#   waydroid-start 270     -> Reverse Portrait (1200x1920)

set -e

ARG="${1:-normal}"

case "$ARG" in
    90|"portrait")
        WIDTH=1200
        HEIGHT=1920
        ROT=1
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
        ROT=3
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

# Baca resolusi saat ini dari waydroid.cfg
CURRENT_WIDTH=$(grep "persist.waydroid.width" /var/lib/waydroid/waydroid.cfg 2>/dev/null | cut -d= -f2 | tr -d ' ' || true)
CURRENT_HEIGHT=$(grep "persist.waydroid.height" /var/lib/waydroid/waydroid.cfg 2>/dev/null | cut -d= -f2 | tr -d ' ' || true)

NEED_RESTART=false

if [ "$CURRENT_WIDTH" != "$WIDTH" ] || [ "$CURRENT_HEIGHT" != "$HEIGHT" ]; then
    echo "Mengatur resolusi Waydroid ke ${WIDTH}x${HEIGHT}..."
    sudo waydroid prop set persist.waydroid.width "$WIDTH"
    sudo waydroid prop set persist.waydroid.height "$HEIGHT"
    NEED_RESTART=true
fi

# Jika sesi sedang berjalan dan resolusi berubah, restart sesi & container
if waydroid status 2>/dev/null | grep -q "RUNNING"; then
    if [ "$NEED_RESTART" = true ]; then
        echo "Me-restart container Waydroid untuk menerapkan resolusi baru..."
        waydroid session stop 2>/dev/null || true
        sleep 1
        sudo systemctl restart waydroid-container.service
    fi
else
    sudo systemctl start waydroid-container.service
fi

# Jalankan sesi Full UI jika belum berjalan
if ! pgrep -f "waydroid show-full-ui" >/dev/null 2>&1; then
    echo "Membuka Waydroid Full UI..."
    waydroid show-full-ui &
fi

# Terapkan rotasi internal Android di latar belakang
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

echo "Waydroid berhasil dijalankan ($MODE_NAME)!"
