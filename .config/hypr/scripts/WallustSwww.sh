#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified by: Fioren (@Leshoraa)
# Wallust: derive colors from the current wallpaper and update templates
# Usage: WallustSwww.sh [absolute_path_to_wallpaper]

set -euo pipefail

CACHE_VERSION="v19"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
palette_cache_dir="$HOME/.cache/wallust/palettes"
dominant_script="$SCRIPTSDIR/extract_dominant.py"
pending_file="/tmp/wallust_pending_target"
lock_file="/tmp/wallust_swww.lock"

get_focused_monitor() {
  hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name; exit}'
}

# 1. Determine wallpaper_path fast (avoid external spawns when path is passed)
passed_path="${1:-}"
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  current_monitor="$(get_focused_monitor || echo 'eDP-1')"
  wallpaper_path=$(awww query 2>/dev/null | awk -v m="$current_monitor" '$0 ~ m {print $NF; exit}')
  if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
    cache_file=$(find "$HOME/.cache/awww/" -name "$current_monitor" -print -quit 2>/dev/null || true)
    if [[ -n "${cache_file:-}" && -f "$cache_file" ]]; then
      wallpaper_path=$(awk '{print $NF}' "$cache_file")
    fi
  fi
  if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]] && [[ -f "$wallpaper_current" ]]; then
    wallpaper_path="$wallpaper_current"
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  exit 0
fi

# Only resolve symlink if needed (0ms fast-path when caller passes realpath)
if [[ -L "$wallpaper_path" || "$wallpaper_path" != /* ]]; then
  real_wp=$(readlink -f "$wallpaper_path" 2>/dev/null || printf '%s' "$wallpaper_path")
else
  real_wp="$wallpaper_path"
fi

# Record latest requested wallpaper atomically (unless caller already set it identically)
current_pending=""
IFS= read -r current_pending < "$pending_file" 2>/dev/null || true
if [[ "$current_pending" != "$real_wp" ]]; then
  tmp_pending="${pending_file}.$$"
  printf '%s\n' "$real_wp" > "$tmp_pending"
  mv -f "$tmp_pending" "$pending_file"
fi

# Non-blocking lock: if another worker is active, exit immediately (<1ms).
exec 200>"$lock_file"
flock -n 200 || exit 0

apply_palette_and_ui() {
  local target_wp="$1"

  ln -sf "$target_wp" "$rofi_link" 2>/dev/null || true

  # Zero-Python fast path when precomputed palette JSON exists (~3.8ms)
  local mtime hash_line hash_key theme_file
  mtime=$(stat -c %Y "$target_wp" 2>/dev/null || echo 0)
  hash_line=$(printf '%s_%s_%s' "$target_wp" "$mtime" "$CACHE_VERSION" | md5sum)
  hash_key="${hash_line%% *}"
  theme_file="$palette_cache_dir/${hash_key}.json"

  if [[ -f "$theme_file" ]]; then
    wallust cs -s --no-hooks -f pywal "$theme_file" >/dev/null 2>&1 || true
  elif [[ -x "$dominant_script" ]]; then
    WALLUST_SKIP_RELOAD=1 "$dominant_script" "$target_wp" >/dev/null 2>&1 || wallust run -s "$target_wp" >/dev/null 2>&1 || true
  else
    wallust run -s "$target_wp" >/dev/null 2>&1 || true
  fi

  # Instant in-place Waybar CSS hot-reload (touch -c avoids pgrep spawn overhead)
  touch -c "$HOME/.config/waybar/style.css" 2>/dev/null || true

  # Update all Hyprland theme colors in a single instant in-memory call (zero config reload lag)
  local hypr_colors="$HOME/.config/hypr/wallust/wallust-hyprland.conf"
  if [[ -f "$hypr_colors" ]]; then
    local lua_payload
    lua_payload=$(awk -F'=' '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^\$primary[ \t]*=/    { pri = trim($2) }
      /^\$color8[ \t]*=/     { c8 = trim($2) }
      /^\$color1[ \t]*=/     { c1 = trim($2) }
      /^\$color11[ \t]*=/    { c11 = trim($2) }
      /^\$color13[ \t]*=/    { c13 = trim($2) }
      /^\$color0[ \t]*=/     { c0 = trim($2) }
      END {
        if (pri != "" && c8 != "") {
          printf "hl.config({ general = { col = { active_border = \"%s\", inactive_border = \"%s\" } }", pri, c8
          if (c1 != "" && c11 != "") {
            printf ", decoration = { shadow = { color = \"%s\", color_inactive = \"%s\" } }", c1, c11
          }
          if (c13 != "" && c0 != "") {
            printf ", group = { col = { border_active = \"%s\" }, groupbar = { col = { active = \"%s\" } } }", c13, c0
          }
          printf " })"
        }
      }
    ' "$hypr_colors")
    [[ -n "$lua_payload" ]] && hyprctl eval "$lua_payload" >/dev/null 2>&1 || true
  fi
}

last_applied=""
while true; do
  target_wp=""
  IFS= read -r target_wp < "$pending_file" 2>/dev/null || true
  if [[ -n "$target_wp" && -f "$target_wp" && "$target_wp" != "$last_applied" ]]; then
    apply_palette_and_ui "$target_wp"
    last_applied="$target_wp"
    continue
  fi

  # Race-free double-check: release lock, then verify no target arrived just before unlock
  exec 200>&-
  newest_wp=""
  IFS= read -r newest_wp < "$pending_file" 2>/dev/null || true
  if [[ -z "$newest_wp" || "$newest_wp" == "$last_applied" ]]; then
    break
  fi
  exec 200>"$lock_file"
  flock -n 200 || break
done

# Async lightweight UI notifications (non-blocking; quickshell auto-reloads qml_color.json via FileView)
(
  swaync-client -rs >/dev/null 2>&1 || true
  pkill -USR1 cava >/dev/null 2>&1 || true
  pkill -x rofi >/dev/null 2>&1 || true

  has_kitty_socket=0
  for sock in /tmp/mykitty*; do
    if [[ -S "$sock" ]]; then
      kitty @ --to "unix:$sock" load-config >/dev/null 2>&1 || true
      has_kitty_socket=1
    fi
  done
  if [[ $has_kitty_socket -eq 0 ]]; then
    pkill -USR1 kitty >/dev/null 2>&1 || true
  fi
) >/dev/null 2>&1 &

# Debounced trailing heavy maintenance (cp .wallpaper_current, Rofi square crop, SDDM)
trailing_pid_file="/tmp/wallust_trailing.pid"
if [[ -f "$trailing_pid_file" ]]; then
  old_pid=""
  IFS= read -r old_pid < "$trailing_pid_file" 2>/dev/null || true
  [[ -n "$old_pid" ]] && kill "$old_pid" >/dev/null 2>&1 || true
fi

(
  sleep 0.40
  final_wp=""
  IFS= read -r final_wp < "$pending_file" 2>/dev/null || true
  [[ -n "$final_wp" && -f "$final_wp" ]] || exit 0

  mkdir -p "$(dirname "$wallpaper_current")"
  wp_cur_src="${wallpaper_current}.source"
  cur_src_val=""
  IFS= read -r cur_src_val < "$wp_cur_src" 2>/dev/null || true
  if [[ "$cur_src_val" != "$final_wp" ]]; then
    printf '%s\n' "$final_wp" > "$wp_cur_src"
    cp -f "$final_wp" "$wallpaper_current" || true
  fi

  rofi_source="$HOME/.config/rofi/.current_wallpaper_square.source"
  rofi_src_val=""
  IFS= read -r rofi_src_val < "$rofi_source" 2>/dev/null || true
  if [[ "$rofi_src_val" != "$final_wp" ]]; then
    printf '%s\n' "$final_wp" > "$rofi_source"
    pkill -f "current_wallpaper_square.png" >/dev/null 2>&1 || true
    nice -n 19 magick "${final_wp}[0]" -resize 500x500^ -gravity center -extent 500x500 "$HOME/.config/rofi/.current_wallpaper_square.png" >/dev/null 2>&1 || true
  fi

  nice -n 19 "$SCRIPTSDIR/sddm_wallpaper.sh" --normal >/dev/null 2>&1 || true
  rm -f "$trailing_pid_file"
) >/dev/null 2>&1 &
echo $! > "$trailing_pid_file"
