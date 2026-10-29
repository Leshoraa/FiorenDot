#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Script for Random Wallpaper (Instant & Spam-Safe Throttled)

set -euo pipefail

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# awww transition config
TYPE="none"
AWWW_PARAMS="--transition-type $TYPE --filter Bilinear"

# Deteksi monitor yang sedang fokus
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null || echo "eDP-1")

# Ambil list wallpaper (Hanya gambar)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.webp" -o -iname "*.bmp" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "Error" "Wallpapers nggak ketemu di $wallDIR"
  exit 1
fi

# Pilih wallpaper random yang BERBEDA dari wallpaper saat ini jika ada >1 wallpaper
current_wall=$(readlink -f "$HOME/.config/rofi/.current_wallpaper" 2>/dev/null || cat "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current" 2>/dev/null || echo "")

if [[ ${#PICS[@]} -gt 1 && -n "$current_wall" ]]; then
  filtered_pics=()
  for p in "${PICS[@]}"; do
    [[ "$p" != "$current_wall" ]] && filtered_pics+=("$p")
  done
  if [[ ${#filtered_pics[@]} -gt 0 ]]; then
    RANDOM_PIC="${filtered_pics[$((RANDOM % ${#filtered_pics[@]}))]}"
  else
    RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
  fi
else
  RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
fi

# 1. Update Config Startup secara asynchronous (tanpa memperlambat pergantian wallpaper)
modify_startup_config() {
  local startup_config="$HOME/.config/hypr/configs/Startup_Apps.conf"
  if grep -q '^\s*#\s*exec-once\s*=\s*awww-daemon' "$startup_config" 2>/dev/null || grep -q '^\s*exec-once\s*=\s*mpvpaper' "$startup_config" 2>/dev/null; then
    sed -i '/^\s*#\s*exec-once\s*=\s*awww-daemon/s/^\s*#\s*//;' "$startup_config" 2>/dev/null || true
    sed -i '/^\s*exec-once\s*=\s*mpvpaper/s/^/\#/' "$startup_config" 2>/dev/null || true
  fi
}
modify_startup_config &

# 2. Terapkan Wallpaper ke monitor secara instan
if ! pgrep -x "awww-daemon" >/dev/null; then
  awww-daemon &
  sleep 0.1
fi
awww img -o "$focused_monitor" "$RANDOM_PIC" $AWWW_PARAMS &

# 3. Eksekusi Warna Wallust (Instan saat single-press, Throttled & Safe saat di-spam)
TARGET_FILE="/tmp/wallpaper_random_target"
TIMER_PID_FILE="/tmp/wallpaper_random_timer.pid"
LAST_RUN_FILE="/tmp/wallpaper_random_last_run"

run_wallust_safe() {
  local target_pic="$1"
  # Hentikan proses Wallust sebelumnya jika masih berjalan agar tidak bentrok
  pkill -f "$SCRIPTSDIR/WallustSwww.sh" 2>/dev/null || true
  pkill -x "wallust" 2>/dev/null || true
  "$SCRIPTSDIR/WallustSwww.sh" "$target_pic" &
}

now_ms=$(date +%s%3N)
last_run=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
diff_ms=$((now_ms - last_run))

echo "$RANDOM_PIC" > "$TARGET_FILE"

# Batalkan timer antrean sebelumnya jika ada
if [[ -f "$TIMER_PID_FILE" ]]; then
  old_timer_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null || true)
  if [[ -n "$old_timer_pid" ]]; then
    kill "$old_timer_pid" 2>/dev/null || true
  fi
fi

if (( diff_ms > 250 )); then
  # Single / spaced press: Eksekusi INSTAN tanpa jeda (0 ms delay)
  echo "$now_ms" > "$LAST_RUN_FILE"
  run_wallust_safe "$RANDOM_PIC"
else
  # Spam detected: Tunggu jeda singkat (200ms) untuk mengeksekusi wallpaper terakhir
  (
    sleep 0.20
    final_pic=$(cat "$TARGET_FILE" 2>/dev/null || true)
    if [[ -n "$final_pic" && -f "$final_pic" ]]; then
      echo "$(date +%s%3N)" > "$LAST_RUN_FILE"
      run_wallust_safe "$final_pic"
    fi
    rm -f "$TIMER_PID_FILE"
  ) >/dev/null 2>&1 &
  echo $! > "$TIMER_PID_FILE"
fi