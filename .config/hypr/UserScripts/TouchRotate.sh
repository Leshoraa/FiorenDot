#!/usr/bin/env bash

# Map ORIENTATION yang dikirim rot8 langsung ke nilai transform Hyprland (0, 1, 2, 3)
# Ini menghindari race condition / delay pembacaan hyprctl monitors
case "$ORIENTATION" in
    "normal")
        TRANSFORM=0
        ;;
    "270")
        TRANSFORM=1
        ;;
    "inverted")
        TRANSFORM=2
        ;;
    "90")
        TRANSFORM=3
        ;;
    *)
        # Fallback jika dijalankan manual tanpa variabel rot8
        sleep 0.1
        TRANSFORM=$(hyprctl monitors -j | jq -r '.[] | select(.name=="eDP-1") | .transform')
        ;;
esac

echo "[$(date)] ORIENTATION=$ORIENTATION -> Set TRANSFORM=$TRANSFORM" >> /tmp/touchrotate.log

if [ -n "$TRANSFORM" ]; then
    # Atur orientasi sentuhan touchscreen & stylus
    hyprctl keyword input:touchdevice:transform "$TRANSFORM" >> /tmp/touchrotate.log 2>&1
    hyprctl keyword input:tablet:transform "$TRANSFORM" >> /tmp/touchrotate.log 2>&1
    hyprctl keyword "device[wdht1f01:00-2575:0911]:transform" "$TRANSFORM" >> /tmp/touchrotate.log 2>&1
    hyprctl keyword "device[wdht1f01:00-2575:0911-stylus]:transform" "$TRANSFORM" >> /tmp/touchrotate.log 2>&1

    # Kontrol Keyboard Virtual (wvkbd)
    if [ "$TRANSFORM" -ne 0 ]; then
        # Mode Tablet / Vertikal: Munculkan keyboard virtual
        pkill -SIGUSR2 wvkbd-mobintl || hyprctl dispatch exec "wvkbd-mobintl -L 300 -H 350"
    else
        # Mode Laptop Biasa: Sembunyikan keyboard virtual
        pkill -SIGUSR1 wvkbd-mobintl
    fi
fi
