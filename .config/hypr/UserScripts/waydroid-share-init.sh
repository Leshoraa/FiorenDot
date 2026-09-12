#!/usr/bin/env bash
# waydroid-share-init: Inisialisasi folder shared antara Linux host dan Waydroid
set -e

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")
WAYDROID_DATA="$USER_HOME/.local/share/waydroid/data"
WAYDROID_MEDIA="$WAYDROID_DATA/media"
WAYDROID_STORAGE="$WAYDROID_MEDIA/0"
SHARED_LINK="$USER_HOME/WaydroidShare"

echo "========================================="
echo " Inisialisasi Folder Shared Waydroid"
echo " User: $USER_NAME"
echo " Host Folder: $SHARED_LINK"
echo "========================================="

if [ ! -d "$WAYDROID_MEDIA" ]; then
    echo "Error: Direktori $WAYDROID_MEDIA tidak ditemukan."
    echo "Pastikan Waydroid sudah diinisialisasi setidaknya sekali."
    exit 1
fi

echo "1. Mengatur izin akses direktori media Waydroid..."
# Berikan izin full dan ACL agar host user ($USER_NAME) dan Android media_rw (1023) bisa baca/tulis
chmod -R 777 "$WAYDROID_MEDIA" 2>/dev/null || true
if command -v setfacl &>/dev/null; then
    setfacl -R -m "u:$USER_NAME:rwx,d:u:$USER_NAME:rwx,u:1023:rwx,d:u:1023:rwx,o::rwx,d:o::rwx" "$WAYDROID_MEDIA" 2>/dev/null || true
fi

echo "2. Memastikan subfolder standar Android ada di /sdcard/..."
mkdir -p "$WAYDROID_STORAGE/Pictures" \
         "$WAYDROID_STORAGE/Documents" \
         "$WAYDROID_STORAGE/Download" \
         "$WAYDROID_STORAGE/DCIM" \
         "$WAYDROID_STORAGE/Movies" \
         "$WAYDROID_STORAGE/Music" \
         "$WAYDROID_STORAGE/Shared"

# Set ownership dan permission di dalam storage
chown -R 1023:1023 "$WAYDROID_MEDIA" 2>/dev/null || true
chmod -R 777 "$WAYDROID_MEDIA" 2>/dev/null || true
if command -v setfacl &>/dev/null; then
    setfacl -R -m "u:$USER_NAME:rwx,d:u:$USER_NAME:rwx,u:1023:rwx,d:u:1023:rwx,o::rwx,d:o::rwx" "$WAYDROID_MEDIA" 2>/dev/null || true
fi

echo "3. Membuat symlink ~/WaydroidShare di direktori Home..."
ln -snf "$WAYDROID_STORAGE" "$SHARED_LINK"
chown -h "$USER_NAME:$USER_NAME" "$SHARED_LINK" 2>/dev/null || true

# Daftarkan ke /usr/local/bin agar dapat dipanggil dengan 'sudo waydroid-share-init'
if [ "$EUID" -eq 0 ]; then
    ln -snf "$USER_HOME/.config/hypr/UserScripts/waydroid-share-init.sh" /usr/local/bin/waydroid-share-init 2>/dev/null || true
    ln -snf "$USER_HOME/.config/hypr/UserScripts/waydroid-rescan.sh" /usr/local/bin/waydroid-rescan 2>/dev/null || true
fi

echo "========================================="
echo " Sukses! Folder penghubung telah aktif di:"
echo " -> $SHARED_LINK"
echo ""
echo " Struktur folder:"
echo "   ~/WaydroidShare/Pictures   -> /sdcard/Pictures (Gambar/Foto)"
echo "   ~/WaydroidShare/Documents  -> /sdcard/Documents (Dokumen/PDF)"
echo "   ~/WaydroidShare/Download   -> /sdcard/Download (File Unduhan)"
echo "   ~/WaydroidShare/Shared     -> /sdcard/Shared (File Bebas)"
echo "========================================="
