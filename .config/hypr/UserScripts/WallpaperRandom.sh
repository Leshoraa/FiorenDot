#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Modified by: Fioren (@Leshoraa)
# Script for Random Wallpaper (Instant Cache-Backed & Spam-Coalesced)

set -euo pipefail

wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_link="$HOME/.config/rofi/.current_wallpaper"

AWWW_PARAMS="--transition-type none --filter Bilinear"
LIST_CACHE="/tmp/wallpaper_random_list.cache"
MON_CACHE="/tmp/wallpaper_focused_monitor.cache"
AWWW_PENDING="/tmp/awww_pending_target"
AWWW_LOCK="/tmp/awww_img.lock"

refresh_list_cache() {
  local tmp="${LIST_CACHE}.$$"
  find -L "${wallDIR}" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
    -iname "*.webp" -o -iname "*.bmp" \) 2>/dev/null | xargs -r readlink -f > "$tmp" 2>/dev/null || true
  if [[ -s "$tmp" ]]; then
    mv -f "$tmp" "$LIST_CACHE"
  else
    rm -f "$tmp"
  fi
}

refresh_monitor_cache() {
  local mon
  mon=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name; exit}')
  [[ -n "${mon:-}" ]] && printf '%s\n' "$mon" > "${MON_CACHE}.$$" && mv -f "${MON_CACHE}.$$" "$MON_CACHE"
}

# 1. Load wallpaper list from fast cache (<1ms), refresh asynchronously if stale
now=${EPOCHSECONDS:-$(date +%s)}
if [[ ! -s "$LIST_CACHE" ]]; then
  refresh_list_cache
else
  cache_mtime=$(stat -c %Y "$LIST_CACHE" 2>/dev/null || echo 0)
  if (( now - cache_mtime > 30 )); then
    refresh_list_cache >/dev/null 2>&1 &
  fi
fi

mapfile -t PICS < "$LIST_CACHE"
if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "Error" "No wallpapers found in $wallDIR"
  exit 1
fi

# 2. Pick random wallpaper different from current (O(1) retry instead of building filtered array)
current_wall=$(readlink -f "$rofi_link" 2>/dev/null || echo "")
n_pics=${#PICS[@]}
RANDOM_PIC="${PICS[$((RANDOM % n_pics))]}"
if (( n_pics > 1 )) && [[ -n "$current_wall" ]]; then
  for _ in 1 2 3 4; do
    [[ "$RANDOM_PIC" != "$current_wall" ]] && break
    RANDOM_PIC="${PICS[$((RANDOM % n_pics))]}"
  done
fi

# 3. Resolve focused monitor from cache (refresh in background if >3s old)
focused_monitor=""
if [[ -s "$MON_CACHE" ]]; then
  focused_monitor=$(< "$MON_CACHE")
  mon_mtime=$(stat -c %Y "$MON_CACHE" 2>/dev/null || echo 0)
  if (( now - mon_mtime > 3 )); then
    refresh_monitor_cache >/dev/null 2>&1 &
  fi
else
  refresh_monitor_cache
  [[ -s "$MON_CACHE" ]] && focused_monitor=$(< "$MON_CACHE")
fi
focused_monitor="${focused_monitor:-eDP-1}"

# 4. Update current symlink and wallust target synchronously (eliminates ordering races)
ln -sf "$RANDOM_PIC" "$rofi_link" 2>/dev/null || true
printf '%s\n' "$RANDOM_PIC" > "/tmp/wallust_pending_target.$$" && mv -f "/tmp/wallust_pending_target.$$" "/tmp/wallust_pending_target"

# 5. Coalesced awww worker (max 1 decoder running even under heavy keybind spam)
printf '%s\n' "$RANDOM_PIC" > "${AWWW_PENDING}.$$" && mv -f "${AWWW_PENDING}.$$" "$AWWW_PENDING"
(
  exec 201>"$AWWW_LOCK"
  flock -n 201 || exit 0
  if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    sleep 0.1
  fi
  applied=""
  while true; do
    target=""
    IFS= read -r target < "$AWWW_PENDING" 2>/dev/null || true
    if [[ -n "$target" && -f "$target" && "$target" != "$applied" ]]; then
      awww img -o "$focused_monitor" "$target" $AWWW_PARAMS >/dev/null 2>&1 || true
      applied="$target"
      continue
    fi
    exec 201>&-
    newest=""
    IFS= read -r newest < "$AWWW_PENDING" 2>/dev/null || true
    [[ -z "$newest" || "$newest" == "$applied" ]] && break
    exec 201>"$AWWW_LOCK"
    flock -n 201 || break
  done
) >/dev/null 2>&1 &

# 6. Trigger instant cache-backed, spam-coalesced Wallust theme update (0ms artificial delay)
"$SCRIPTSDIR/WallustSwww.sh" "$RANDOM_PIC" >/dev/null 2>&1 &
