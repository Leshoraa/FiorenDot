#!/usr/bin/env bash
# FiorenDot - Sync active system configs to dotfiles repo
# Usage: ./sync-from-system.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE="${XDG_CONFIG_HOME:-$HOME/.config}"
HOME_SOURCE="$HOME"

echo "========================================"
echo "    FiorenDot: Sync from System        "
echo "========================================"
echo "System Source : $CONFIG_SOURCE"
echo "Repo Target   : $DOTFILES_DIR"
echo "========================================"

# Common exclusions
EXCLUDE_ARGS=(
    --exclude="*.bak*"
    --exclude="*.save*"
    --exclude="*.swp"
    --exclude="*~"
    --exclude="*.log"
    --exclude=".DS_Store"
    --exclude="__pycache__"
    --exclude="*.pyc"
    --exclude=".initial_startup_done"
    --exclude=".current_wallpaper*"
    --exclude="*.disabled"
    --exclude="*.wants"
)

# 1. Sync tracked .config folders
if [ -d "$DOTFILES_DIR/.config" ]; then
    for repo_item in "$DOTFILES_DIR/.config"/*; do
        [ -e "$repo_item" ] || continue
        base="$(basename "$repo_item")"
        sys_item="$CONFIG_SOURCE/$base"
        
        if [ -d "$sys_item" ]; then
            rsync -av --delete "${EXCLUDE_ARGS[@]}" "$sys_item/" "$repo_item/"
        elif [ -f "$sys_item" ]; then
            cp -p "$sys_item" "$repo_item"
        fi
    done
fi

# 2. Sync systemd user overrides if present
if [ -d "$CONFIG_SOURCE/systemd/user/swaync.service.d" ]; then
    mkdir -p "$DOTFILES_DIR/.config/systemd/user/swaync.service.d"
    rsync -av "$CONFIG_SOURCE/systemd/user/swaync.service.d/" "$DOTFILES_DIR/.config/systemd/user/swaync.service.d/"
fi

# 3. Sync home dotfiles
for home_file in .zshrc .zprofile; do
    if [ -f "$HOME_SOURCE/$home_file" ]; then
        cp -p "$HOME_SOURCE/$home_file" "$DOTFILES_DIR/$home_file"
    fi
done

echo "========================================"
echo "✅ Sync complete! Check changes with 'git status'"
echo "========================================"
