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
    --exclude="*.pre_*"
)

# 1. Sync tracked .config folders & files
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

# 3. Sync .local/bin scripts
if [ -d "$DOTFILES_DIR/.local/bin" ]; then
    for bin_item in "$DOTFILES_DIR/.local/bin"/*; do
        [ -e "$bin_item" ] || continue
        base="$(basename "$bin_item")"
        sys_bin="$HOME_SOURCE/.local/bin/$base"
        if [ -f "$sys_bin" ]; then
            cp -p "$sys_bin" "$bin_item"
        fi
    done
fi

# 4. Sync .local/share/easyeffects presets
if [ -d "$DOTFILES_DIR/.local/share/easyeffects" ] && [ -d "$HOME_SOURCE/.local/share/easyeffects" ]; then
    rsync -av --delete "${EXCLUDE_ARGS[@]}" "$HOME_SOURCE/.local/share/easyeffects/" "$DOTFILES_DIR/.local/share/easyeffects/"
fi

# 5. Sync home dotfiles
for home_file in .zshrc .zprofile; do
    if [ -f "$HOME_SOURCE/$home_file" ]; then
        cp -p "$HOME_SOURCE/$home_file" "$DOTFILES_DIR/$home_file"
    fi
done

# 6. Sync system hardware, power & kernel configs if present
mkdir -p "$DOTFILES_DIR/system/power" "$DOTFILES_DIR/system/gpu" "$DOTFILES_DIR/system/input"

# Power & battery
if [ -f "/usr/lib/systemd/system-sleep/battery-limit-rtc.sh" ]; then
    cp -p "/usr/lib/systemd/system-sleep/battery-limit-rtc.sh" "$DOTFILES_DIR/system/power/battery-limit-rtc.sh"
fi
if [ -f "/usr/local/bin/power-state-sync.sh" ]; then
    cp -p "/usr/local/bin/power-state-sync.sh" "$DOTFILES_DIR/system/power/power-state-sync.sh"
fi
if [ -f "/etc/udev/rules.d/99-battery-charge-threshold.rules" ]; then
    cp -p "/etc/udev/rules.d/99-battery-charge-threshold.rules" "$DOTFILES_DIR/system/power/99-battery-charge-threshold.rules"
fi
if [ -f "/etc/udev/rules.d/99-powersave.rules" ]; then
    cp -p "/etc/udev/rules.d/99-powersave.rules" "$DOTFILES_DIR/system/power/99-powersave.rules"
fi
if [ -f "/etc/udev/rules.d/50-amd-epp.rules" ]; then
    cp -p "/etc/udev/rules.d/50-amd-epp.rules" "$DOTFILES_DIR/system/power/50-amd-epp.rules"
fi
if [ -f "/etc/modprobe.d/asus_wmi.conf" ]; then
    cp -p "/etc/modprobe.d/asus_wmi.conf" "$DOTFILES_DIR/system/power/asus_wmi.conf"
fi
if [ -f "/etc/systemd/system/asus-battery-charge-threshold.service" ]; then
    cp -p "/etc/systemd/system/asus-battery-charge-threshold.service" "$DOTFILES_DIR/system/power/asus-battery-charge-threshold.service"
fi

# GPU
if [ -f "/etc/udev/rules.d/60-amdgpu-power.rules" ]; then
    cp -p "/etc/udev/rules.d/60-amdgpu-power.rules" "$DOTFILES_DIR/system/gpu/60-amdgpu-power.rules"
fi
if [ -f "/etc/modprobe.d/amdgpu.conf" ]; then
    cp -p "/etc/modprobe.d/amdgpu.conf" "$DOTFILES_DIR/system/gpu/amdgpu.conf"
fi

# Input & Touchpad
if [ -f "/etc/udev/rules.d/80-uinput.rules" ]; then
    cp -p "/etc/udev/rules.d/80-uinput.rules" "$DOTFILES_DIR/system/input/80-uinput.rules"
fi
if [ -f "/etc/systemd/system/asus_touchpad_numpad.service" ]; then
    cp -p "/etc/systemd/system/asus_touchpad_numpad.service" "$DOTFILES_DIR/system/input/asus_touchpad_numpad.service"
fi

# VM / ZRAM
if [ -f "/etc/sysctl.d/99-zram.conf" ]; then
    cp -p "/etc/sysctl.d/99-zram.conf" "$DOTFILES_DIR/system/99-zram.conf"
fi

echo "========================================"
echo "✅ Sync complete! Check changes with 'git status'"
echo "========================================"
