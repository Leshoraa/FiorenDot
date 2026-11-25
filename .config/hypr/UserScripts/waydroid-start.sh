#!/usr/bin/env bash
# waydroid-start: Start Waydroid with specified resolution & orientation
# Usage:
#   waydroid-start         -> Normal Landscape (1920x1200)
#   waydroid-start 90      -> Portrait (1200x1920)
#   waydroid-start 180     -> Inverted Landscape (1920x1200)
#   waydroid-start 270     -> Reverse Portrait (1200x1920)

set -e

# Ensure state directory exists to avoid Waydroid user_migration crash
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

# 1. Stop any active session
if waydroid status 2>/dev/null | grep -q "RUNNING"; then
    echo "Stopping active Waydroid session..."
    waydroid session stop 2>/dev/null || true
    sleep 1
fi

# 2. Apply target resolution
echo "Setting Waydroid resolution to ${WIDTH}x${HEIGHT}..."
sudo waydroid prop set persist.waydroid.width "$WIDTH"
sudo waydroid prop set persist.waydroid.height "$HEIGHT"

# 3. Ensure shared host storage (~/WaydroidShare) is initialized
if [ -f "$HOME/.config/hypr/UserScripts/waydroid-share-init.sh" ]; then
    sudo "$HOME/.config/hypr/UserScripts/waydroid-share-init.sh" >/dev/null 2>&1 || true
fi

# 4. Restart container to pick up resolution properties
echo "Restarting Waydroid service..."
sudo systemctl restart waydroid-container.service

# 5. Launch Full UI
echo "Launching Waydroid UI..."
waydroid show-full-ui &

# 6. Apply orientation lock when inverted
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

echo "Waydroid started ($MODE_NAME)."
