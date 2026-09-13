#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Script for Random Wallpaper (Fast Fade - No SDDM)

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# awww transition config (Sinkron dengan script Select: Fast Fade)
TYPE="none"
AWWW_PARAMS="--transition-type $TYPE --filter Bilinear"

# Deteksi monitor yang sedang fokus
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null || echo "eDP-1")

# Ambil list wallpaper (Hanya gambar)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.webp" -o -iname "*.bmp" \) -print0)

# Pilih satu secara random
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"

# Fungsi Update Startup Config (Biar tetap ada pas reboot)
modify_startup_config() {
  local startup_config="$HOME/.config/hypr/configs/Startup_Apps.conf"
  # Pastikan awww aktif dan mpvpaper (video) mati di startup
  sed -i '/^\s*#\s*exec-once\s*=\s*awww-daemon/s/^\s*#\s*//;' "$startup_config" 2>/dev/null || true
  sed -i '/^\s*exec-once\s*=\s*mpvpaper/s/^/\#/' "$startup_config" 2>/dev/null || true
}

# --- Eksekusi ---

if [[ -n "$RANDOM_PIC" ]]; then
  # 1. Update Config Startup
  modify_startup_config
  
  # 2. Apply Wallpaper ke monitor yang fokus
  if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &
    sleep 0.1
  fi
  awww img -o "$focused_monitor" "$RANDOM_PIC" $AWWW_PARAMS
  
  # 3. Update Warna UI lewat Wallust (Otomatis reload Waybar, SwayNC, Rofi, Kitty)
  "$SCRIPTSDIR/WallustSwww.sh" "$RANDOM_PIC"
else
  notify-send "Error" "Wallpapers nggak ketemu di $wallDIR"
fi