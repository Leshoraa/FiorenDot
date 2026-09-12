#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Searching via web browsers

# Define the path to the config file
config_file=$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Extract Search_Engine cleanly without fragile eval
Search_Engine=$(grep -E '^\s*\$Search_Engine\s*=' "$config_file" | sed -E 's/^\s*\$Search_Engine\s*=\s*([^#]*).*/\1/' | sed "s/[\"'\r]//g" | xargs)
Search_Engine=${Search_Engine:-"https://www.google.com/search?q={}"}

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='note: search via default web browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Open Rofi and pass the selected query to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_theme" | xargs -I{} xdg-open $Search_Engine