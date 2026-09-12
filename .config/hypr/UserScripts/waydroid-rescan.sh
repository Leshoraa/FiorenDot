#!/usr/bin/env bash
# waydroid-rescan: Trigger Android MediaScanner to refresh files in Waydroid

if ! waydroid status 2>/dev/null | grep -q "RUNNING"; then
    echo "Waydroid tidak sedang berjalan."
    exit 0
fi

echo "Menyegarkan galeri & dokumen di Waydroid..."
TARGET="${1:-all}"

case "$TARGET" in
    pictures|gambar)
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Pictures" >/dev/null 2>&1 || true
        ;;
    documents|dokumen)
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Documents" >/dev/null 2>&1 || true
        ;;
    download|downloads)
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Download" >/dev/null 2>&1 || true
        ;;
    *)
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Pictures" >/dev/null 2>&1 || true
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Documents" >/dev/null 2>&1 || true
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Download" >/dev/null 2>&1 || true
        sudo waydroid shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Shared" >/dev/null 2>&1 || true
        ;;
esac

echo "Selesai! MediaScanner Waydroid telah diperbarui."
