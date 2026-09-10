#!/usr/bin/env bash
# FiorenDot Installer & Linker Script
# Usage: ./install.sh [--symlink | --copy] [--backup] [--dry-run]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
HOME_TARGET="$HOME"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
MODE="symlink"
DRY_RUN=false
DO_BACKUP=true

print_usage() {
    cat << HELP
FiorenDot Installer Script

Usage:
  ./install.sh [options]

Options:
  -s, --symlink    Create symlinks from dotfiles to target directories (default)
  -c, --copy       Copy files directly instead of symlinking
  -n, --dry-run    Show what would be done without making changes
  --no-backup      Skip backing up existing configs
  -h, --help       Show this help message
HELP
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--symlink)
            MODE="symlink"
            shift
            ;;
        -c|--copy)
            MODE="copy"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-backup)
            DO_BACKUP=false
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "========================================"
echo "         FiorenDot Installer           "
echo "========================================"
echo "Dotfiles Source : $DOTFILES_DIR"
echo "Config Target   : $CONFIG_TARGET"
echo "Mode            : $MODE"
echo "Dry Run         : $DRY_RUN"
echo "========================================"

backup_item() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$DO_BACKUP" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY-RUN] Would backup $target -> $BACKUP_DIR/"
            else
                mkdir -p "$BACKUP_DIR"
                echo "Backing up $target to $BACKUP_DIR/"
                mv "$target" "$BACKUP_DIR/"
            fi
        else
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY-RUN] Would remove existing $target"
            else
                rm -rf "$target"
            fi
        fi
    fi
}

deploy_config() {
    local src="$1"
    local dest="$2"

    backup_item "$dest"

    if [ "$DRY_RUN" = true ]; then
        if [ "$MODE" = "symlink" ]; then
            echo "[DRY-RUN] ln -snf \"$src\" \"$dest\""
        else
            echo "[DRY-RUN] cp -a \"$src\" \"$dest\""
        fi
    else
        mkdir -p "$(dirname "$dest")"
        if [ "$MODE" = "symlink" ]; then
            ln -snf "$src" "$dest"
            echo "Linked: $dest -> $src"
        else
            cp -a "$src" "$dest"
            echo "Copied: $src -> $dest"
        fi
    fi
}

# Deploy .config folders & files
if [ -d "$DOTFILES_DIR/.config" ]; then
    for item in "$DOTFILES_DIR/.config"/*; do
        [ -e "$item" ] || continue
        base="$(basename "$item")"
        deploy_config "$item" "$CONFIG_TARGET/$base"
    done
fi

# Deploy home dotfiles (.zshrc, .zprofile, etc.)
for home_file in .zshrc .zprofile; do
    if [ -f "$DOTFILES_DIR/$home_file" ]; then
        deploy_config "$DOTFILES_DIR/$home_file" "$HOME_TARGET/$home_file"
    fi
done

echo "========================================"
echo "Installation complete!"
if [ "$DO_BACKUP" = true ] && [ -d "$BACKUP_DIR" ]; then
    echo "Backups saved in: $BACKUP_DIR"
fi
echo "========================================"
