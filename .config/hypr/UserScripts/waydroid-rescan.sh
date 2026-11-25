#!/usr/bin/env bash
# waydroid-rescan: Trigger Android MediaScanner to refresh files in Waydroid Gallery/MediaStore

if ! waydroid status 2>/dev/null | grep -q "RUNNING"; then
    echo "Waydroid is not running. Start Waydroid first."
    exit 0
fi

echo "==> Refreshing Waydroid MediaStore..."

# 1. Android 11+: scan external_primary volume via MediaProvider
sudo waydroid shell content call --uri content://media --method scan_volume --arg external_primary >/dev/null 2>&1 || true

# 2. Fallback intent broadcast per file under /sdcard/
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

echo "==> Done. Android MediaStore updated."
