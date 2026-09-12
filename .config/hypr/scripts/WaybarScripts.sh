#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# This file used on waybar modules sourcing defaults set in $HOME/.config/hypr/UserConfigs/01-UserDefaults.conf

# Define the path to the config file
config_file=$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Extract variables cleanly without fragile eval
term=$(grep -E '^\s*\$term\s*=' "$config_file" | sed -E 's/^\s*\$term\s*=\s*([^#]*).*/\1/' | sed "s/[\"'\r]//g" | xargs)
files=$(grep -E '^\s*\$files\s*=' "$config_file" | sed -E 's/^\s*\$files\s*=\s*([^#]*).*/\1/' | sed "s/[\"'\r]//g" | xargs)

# Fallback defaults if empty
term=${term:-kitty}
files=${files:-thunar}

# Execute accordingly based on the passed argument
if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--battop" ]]; then
    $term --title battop sh -c 'battop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    $files &
else
    echo "Usage: $0 [--btop | --nvtop | --battop | --nmtui | --term | --files]"
    echo "--btop       : Open btop in a new term"
    echo "--nvtop      : Open nvtop in a new term"
    echo "--battop     : Open battop in a new term"
    echo "--nmtui      : Open nmtui in a new term"
    echo "--term       : Launch a term window"
    echo "--files      : Launch a file manager"
fi