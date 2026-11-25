#!/usr/bin/env bash
# waydroid-share-init: Initialize shared host/Waydroid storage symlink
set -e

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")
WAYDROID_DATA="$USER_HOME/.local/share/waydroid/data"
WAYDROID_MEDIA="$WAYDROID_DATA/media"
WAYDROID_STORAGE="$WAYDROID_MEDIA/0"
SHARED_LINK="$USER_HOME/WaydroidShare"

echo "========================================="
echo " Initializing Waydroid Shared Storage"
echo " User: $USER_NAME"
echo " Host Link: $SHARED_LINK"
echo "========================================="

if [ ! -d "$WAYDROID_MEDIA" ]; then
    echo "Error: $WAYDROID_MEDIA not found." >&2
    echo "Initialize Waydroid at least once first." >&2
    exit 1
fi

echo "1. Setting Waydroid media ACLs & permissions..."
# Grant RWX ACLs for host user and Android media_rw (uid 1023)
chmod -R 777 "$WAYDROID_MEDIA" 2>/dev/null || true
if command -v setfacl &>/dev/null; then
    setfacl -R -m "u:$USER_NAME:rwx,d:u:$USER_NAME:rwx,u:1023:rwx,d:u:1023:rwx,o::rwx,d:o::rwx" "$WAYDROID_MEDIA" 2>/dev/null || true
fi

echo "2. Ensuring standard Android subfolders exist..."
mkdir -p "$WAYDROID_STORAGE/Pictures" \
         "$WAYDROID_STORAGE/Documents" \
         "$WAYDROID_STORAGE/Download" \
         "$WAYDROID_STORAGE/DCIM" \
         "$WAYDROID_STORAGE/Movies" \
         "$WAYDROID_STORAGE/Music" \
         "$WAYDROID_STORAGE/Shared"

# Apply Android media_rw ownership and ACLs
chown -R 1023:1023 "$WAYDROID_MEDIA" 2>/dev/null || true
chmod -R 777 "$WAYDROID_MEDIA" 2>/dev/null || true
if command -v setfacl &>/dev/null; then
    setfacl -R -m "u:$USER_NAME:rwx,d:u:$USER_NAME:rwx,u:1023:rwx,d:u:1023:rwx,o::rwx,d:o::rwx" "$WAYDROID_MEDIA" 2>/dev/null || true
fi

echo "3. Creating ~/WaydroidShare symlink..."
ln -snf "$WAYDROID_STORAGE" "$SHARED_LINK"
chown -h "$USER_NAME:$USER_NAME" "$SHARED_LINK" 2>/dev/null || true

# Install helpers into /usr/local/bin when run as root
if [ "$EUID" -eq 0 ]; then
    ln -snf "$USER_HOME/.config/hypr/UserScripts/waydroid-share-init.sh" /usr/local/bin/waydroid-share-init 2>/dev/null || true
    ln -snf "$USER_HOME/.config/hypr/UserScripts/waydroid-rescan.sh" /usr/local/bin/waydroid-rescan 2>/dev/null || true
fi

echo "========================================="
echo " Done. Shared directory active at: $SHARED_LINK"
echo ""
echo " Layout:"
echo "   ~/WaydroidShare/Pictures   -> /sdcard/Pictures"
echo "   ~/WaydroidShare/Documents  -> /sdcard/Documents"
echo "   ~/WaydroidShare/Download   -> /sdcard/Download"
echo "   ~/WaydroidShare/Shared     -> /sdcard/Shared"
echo "========================================="
