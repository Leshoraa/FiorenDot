#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust: derive colors from the current wallpaper and update templates
# Usage: Wallustawww.sh [absolute_path_to_wallpaper]

set -euo pipefail


# Inputs and paths
passed_path="${1:-}"
cache_dir="$HOME/.cache/awww/"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Helper: get focused monitor name (prefer JSON)
get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

# Determine wallpaper_path
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  current_monitor="$(get_focused_monitor 2>/dev/null || echo 'eDP-1')"
  # Directly query awww for the wallpaper path
  wallpaper_path=$(awww query 2>/dev/null | grep "$current_monitor" | awk '{print $NF}')

  if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
    # Fallback to awww cache file if query did not return a path
    cache_file=$(find "$cache_dir" -name "$current_monitor" -print -quit 2>/dev/null || true)
    if [[ -n "${cache_file:-}" && -f "$cache_file" ]]; then
      wallpaper_path=$(awk '{print $NF}' "$cache_file")
    fi
  fi

  if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
    if [[ -f "$wallpaper_current" ]]; then
      wallpaper_path="$wallpaper_current"
    fi
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  exit 0
fi

# Update helpers that depend on the path
ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

# Generate 1:1 center-cropped square wallpaper for Rofi only if source changed
rofi_source="$HOME/.config/rofi/.current_wallpaper_square.source"
if [[ ! -f "$rofi_source" || "$(< "$rofi_source")" != "$wallpaper_path" ]]; then
  echo "$wallpaper_path" > "$rofi_source"
  pkill -f "current_wallpaper_square.png" 2>/dev/null || true
  magick "$wallpaper_path"[0] -resize 500x500^ -gravity center -extent 500x500 "$HOME/.config/rofi/.current_wallpaper_square.png" >/dev/null 2>&1 &
fi

# Derive colors prioritizing largest pixel area (warna paling banyak)
dominant_script="$HOME/.config/hypr/scripts/extract_dominant.py"
if [[ -x "$dominant_script" ]]; then
  "$dominant_script" "$wallpaper_path" || wallust run -s "$wallpaper_path" || true
else
  wallust run -s "$wallpaper_path" || true
fi

# Reload UI components with fresh colors
touch ~/.config/kitty/kitty.conf; pkill -USR1 kitty 2>/dev/null || true
pkill -USR2 waybar 2>/dev/null || true
hyprctl reload 2>/dev/null || true
swaync-client -rs 2>/dev/null || true
pkill -USR1 cava 2>/dev/null || true
pkill -x rofi 2>/dev/null || true

# Reload quickshell overview if running so launcher picks up new colors
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
  pkill -x qs 2>/dev/null || true
  pkill -x quickshell 2>/dev/null || true
  qs -c overview -d >/dev/null 2>&1 &
fi