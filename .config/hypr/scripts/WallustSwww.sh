#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust: derive colors from the current wallpaper and update templates
# Usage: Wallustawww.sh [absolute_path_to_wallpaper]

set -euo pipefail

# Auto-boost CPU temporarily for instant color derivation if currently in power-saver
if [[ -z "${WALLUST_BOOSTED:-}" ]] && command -v powerprofilesctl >/dev/null 2>&1; then
  if [[ "$(powerprofilesctl get 2>/dev/null)" == "power-saver" ]]; then
    export WALLUST_BOOSTED=1
    exec powerprofilesctl launch --profile performance -- "$0" "$@"
  fi
fi

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
  # Try to read from awww cache for the focused monitor, with a short retry loop
  current_monitor="$(get_focused_monitor)"
  cache_file="$cache_dir$current_monitor"

  # Wait briefly for awww to write its cache after an image change
  for i in {1..10}; do
    if [[ -f "$cache_file" ]]; then
      break
    fi
    sleep 0.1
  done

  if [[ -f "$cache_file" ]]; then
    # The first non-filter line is the original wallpaper path
    # wallpaper_path="$(grep -v 'Lanczos3' "$cache_file" | head -n 1)"
    wallpaper_path=$(awww query | grep $current_monitor | awk '{print $9}')
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

# Generate 1:1 center-cropped square wallpaper for Rofi Fio theme
magick "$wallpaper_path" -gravity center -crop 1:1 +repage -resize 500x500 "$HOME/.config/rofi/.current_wallpaper_square.png" || true

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
wallust run -s "$wallpaper_path" || true
pkill -USR1 kitty || true
pkill -USR1 cava || true
pkill -USR2 waybar || true

# Reload quickshell overview if running so launcher picks up new colors
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
  pkill -x qs 2>/dev/null || true
  pkill -x quickshell 2>/dev/null || true
  qs -c overview >/dev/null 2>&1 &
fi

# Close any running rofi instances to load fresh colors on next open
pkill -x rofi 2>/dev/null || true

# Reload Hyprland borders and SwayNC notification center
hyprctl reload 2>/dev/null || true
swaync-client -rs 2>/dev/null || true