#!/usr/bin/env bash
# waydroid-rescan: Trigger Android MediaScanner to refresh files in Waydroid Gallery/MediaStore

if ! waydroid status 2>/dev/null | grep -q "RUNNING"; then
    echo "Waydroid tidak sedang berjalan. Jalankan Waydroid terlebih dahulu."
    exit 0
fi

echo "==> Menyegarkan database media & galeri di Waydroid..."

# 1. Metode Android 11+: Scan volume external_primary melalui MediaProvider
sudo waydroid shell content call --uri content://media --method scan_volume --arg external_primary >/dev/null 2>&1 || true

# 2. Metode intent broadcast untuk setiap file media yang ada di /sdcard/
sudo waydroid shell sh -c '
for folder in /sdcard/Pictures /sdcard/DCIM /sdcard/Movies /sdcard/Download /sdcard/Documents /sdcard/Shared; do
    if [ -d "$folder" ]; then
        for f in "$folder"/*; do
            if [ -f "$f" ]; then
                am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$f" >/dev/null 2>&1
            fi
        done
    fi
done
' || true

echo "==> Selesai! Galeri, Video, dan MediaStore Android telah diperbarui."
