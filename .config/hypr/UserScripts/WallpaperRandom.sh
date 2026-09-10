#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Script for Random Wallpaper (Fast Fade - No SDDM)

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# awww transition config (Sinkron dengan script Select: Fast Fade)
TYPE="none"
AWWW_PARAMS="--transition-type $TYPE"

# Deteksi monitor yang sedang fokus
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ambil list wallpaper (Hanya gambar)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.webp" -o -iname "*.bmp" \) -print0)

# Pilih satu secara random
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"

# Fungsi Update Startup Config (Biar tetap ada pas reboot)
modify_startup_config() {
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  # Pastikan awww aktif dan mpvpaper (video) mati di startup
  sed -i '/^\s*#\s*exec-once\s*=\s*awww-daemon\s*--format\s*xrgb\s*$/s/^\s*#\s*//;' "$startup_config"
  sed -i '/^\s*exec-once\s*=\s*mpvpaper\s*.*$/s/^/\#/' "$startup_config"
}

# --- Eksekusi ---

if [[ -n "$RANDOM_PIC" ]]; then
  # 1. Update Config Startup
  modify_startup_config
  
  # 2. Apply Wallpaper ke monitor yang fokus
  awww query || awww-daemon --format xrgb &
  awww img -o "$focused_monitor" "$RANDOM_PIC" $AWWW_PARAMS
  
  # 3. Update Warna UI lewat Wallust (Ini sekarang otomatis me-reload Waybar dengan mulus)
  "$SCRIPTSDIR/WallustSwww.sh" "$RANDOM_PIC"
  
  # 4. Reload SwayNC
  swaync-client -rs
else
  notify-send "Error" "Wallpapers nggak ketemu di $wallDIR"
fi