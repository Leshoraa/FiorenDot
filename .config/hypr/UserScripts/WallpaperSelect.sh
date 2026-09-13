#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# awww transition config
TYPE="none"
AWWW_PARAMS="--transition-type $TYPE --filter Bilinear"

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"

# Kill existing wallpaper daemons for video
kill_wallpaper_for_video() {
  awww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Kill existing wallpaper daemons for image
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Retrieve wallpapers (both images & videos)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi command
rofi_command="rofi -i -show-icons -show -dmenu -config $rofi_theme"

# Sorting Wallpapers
menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))

  cache_dir="$HOME/.cache/rofi_wallpaper_preview"
  mkdir -p "$cache_dir"

  random_thumb="$cache_dir/${RANDOM_PIC##*/}.png"
  if [[ -f "$random_thumb" ]]; then
    printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$random_thumb"
  else
    printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"
  fi

  for pic_path in "${sorted_options[@]}"; do
    pic_name="${pic_path##*/}"
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" || "$pic_path" -nt "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 350x197^ -gravity center -extent 350x197 \
          \( +clone -threshold -1 -draw "fill black polygon 0,0 0,16 16,0 fill white circle 16,16 16,0" \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
          -alpha off -compose CopyOpacity -composite "$cache_gif_image" 2>/dev/null || true
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" || "$pic_path" -nt "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
        magick "$cache_preview_image" -resize 350x197^ -gravity center -extent 350x197 \
          \( +clone -threshold -1 -draw "fill black polygon 0,0 0,16 16,0 fill white circle 16,16 16,0" \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
          -alpha off -compose CopyOpacity -composite "$cache_preview_image" 2>/dev/null || true
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
    else
      thumb="$cache_dir/${pic_name}.png"
      if [[ ! -f "$thumb" || "$pic_path" -nt "$thumb" ]]; then
        magick "$pic_path" -resize 350x197^ -gravity center -extent 350x197 \
          \( +clone -threshold -1 -draw "fill black polygon 0,0 0,16 16,0 fill white circle 16,16 16,0" \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
          -alpha off -compose CopyOpacity -composite "$thumb" 2>/dev/null || thumb="$pic_path"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$thumb"
    fi
  done
}

# Offer SDDM Simple Wallpaper Option (only for non-video wallpapers)
set_sddm_wallpaper() {
  local sddm_themes_dir="/usr/share/sddm/themes"
  if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
  fi

  local sddm_simple="$sddm_themes_dir/simple_sddm_2"

  if [ -d "$sddm_simple" ] && [ -w "$sddm_simple" ]; then
    "$SCRIPTSDIR/sddm_wallpaper.sh" --normal >/dev/null 2>&1 &
  fi
}

modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/configs/Startup_Apps.conf"

  # Check if it's a live wallpaper (video)
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # For video wallpapers:
    sed -i '/^\s*exec-once\s*=\s*awww-daemon/s/^/\#/' "$startup_config" 2>/dev/null || true
    sed -i '/^\s*#\s*exec-once\s*=\s*mpvpaper/s/^#\s*//;' "$startup_config" 2>/dev/null || true

    # Update the livewallpaper variable with the selected video path (using $HOME)
    selected_file="${selected_file/#$HOME/\$HOME}"
    sed -i "s|^\$livewallpaper=.*|\$livewallpaper=\"$selected_file\"|" "$startup_config" 2>/dev/null || true
  else
    # For image wallpapers:
    sed -i '/^\s*#\s*exec-once\s*=\s*awww-daemon/s/^\s*#\s*//;' "$startup_config" 2>/dev/null || true
    sed -i '/^\s*exec-once\s*=\s*mpvpaper/s/^/\#/' "$startup_config" 2>/dev/null || true
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"
  local focused_monitor
  focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null || echo "eDP-1")

  kill_wallpaper_for_image

  if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &
    sleep 0.1
  fi

  awww img -o "$focused_monitor" "$image_path" $AWWW_PARAMS &

  # 1. Update warna UI (Otomatis reload Waybar, SwayNC, Rofi, Kitty)
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"

  set_sddm_wallpaper &
}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Apply video wallpaper using mpvpaper
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

# Main function
main() {
  choice=$(menu | $rofi_command)
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  # Dismiss rofi immediately so the transition is seen right away
  pkill -x rofi 2>/dev/null || true

  # Handle random selection correctly
  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    choice=$(basename "$RANDOM_PIC")
  fi

  choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')

  # Search for the selected file in the wallpapers directory, including subdirectories
  selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

  if [[ -z "$selected_file" ]]; then
    echo "File not found. Selected choice: $choice"
    exit 1
  fi

  # Modify the Startup_Apps.conf file asynchronously
  modify_startup_config "$selected_file" &

  # **CHECK FIRST** if it's a video or an image **before calling any function**
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main
