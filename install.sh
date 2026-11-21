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

# Options:
#   -s, --symlink    Create symlinks from dotfiles to target directories (default)
#   -c, --copy       Copy files directly instead of symlinking
#   -n, --dry-run    Show what would be done without making changes
#   --force          Bypass strict device lock check
#   --no-backup      Skip backing up existing configs
#   -h, --help       Show this help message

FORCE_INSTALL=false

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
        --force)
            FORCE_INSTALL=true
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

# Strict device lock check
CURRENT_USER="$(whoami 2>/dev/null || echo "$USER")"
CURRENT_HOST="$(hostname 2>/dev/null || uname -n)"

if [[ "$CURRENT_USER" != "fioren" || "$CURRENT_HOST" != "leviola" ]]; then
    echo "=========================================================="
    echo "⚠️  PERINGATAN KERAS / STRICT DEVICE LOCK:                "
    echo "   Repositori ini dikhususkan secara eksklusif untuk     "
    echo "   perangkat pribadi milik Fioren (@Leshoraa)            "
    echo "   (ASUS Vivobook S 14 Flip TN3402QA / leviola).         "
    echo "   Banyak pengaturan hardware (ACPI, udev rules, EPP,    "
    echo "   battery threshold, touchpad numpad) yang dirancang    "
    echo "   hanya untuk hardware ini dan TIDAK BOLEH dipasang     "
    echo "   di perangkat lain!                                    "
    echo "=========================================================="
    if [[ "$FORCE_INSTALL" != "true" ]]; then
        echo "❌ Instalasi dibatalkan demi keamanan hardware Anda."
        echo "   (Gunakan --force hanya jika Anda tahu persis apa yang Anda lakukan)"
        exit 1
    fi
fi

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

# Deploy .local/bin scripts
if [ -d "$DOTFILES_DIR/.local/bin" ]; then
    mkdir -p "$HOME_TARGET/.local/bin"
    for bin_item in "$DOTFILES_DIR/.local/bin"/*; do
        [ -e "$bin_item" ] || continue
        base="$(basename "$bin_item")"
        deploy_config "$bin_item" "$HOME_TARGET/.local/bin/$base"
    done
fi

# Deploy .local/share presets (e.g. EasyEffects)
if [ -d "$DOTFILES_DIR/.local/share" ]; then
    for share_item in "$DOTFILES_DIR/.local/share"/*; do
        [ -e "$share_item" ] || continue
        base="$(basename "$share_item")"
        deploy_config "$share_item" "$HOME_TARGET/.local/share/$base"
    done
fi

# Deploy wallpapers
if [ -d "$DOTFILES_DIR/wallpapers" ]; then
    mkdir -p "$HOME_TARGET/Pictures"
    deploy_config "$DOTFILES_DIR/wallpapers" "$HOME_TARGET/Pictures/wallpapers"
fi

# Deploy home dotfiles (.zshrc, .zprofile, .gtkrc-2.0, etc.)
for home_file in .zshrc .zprofile .gtkrc-2.0; do
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
