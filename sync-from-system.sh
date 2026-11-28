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
    --exclude=".wallpaper_current.source"
    --exclude="*.disabled"
    --exclude="*.wants"
    --exclude="*.pre_*"
)

same_target() {
    local a="$1" b="$2"
    [ -e "$a" ] && [ -e "$b" ] && [ "$(readlink -f "$a")" = "$(readlink -f "$b")" ]
}

safe_copy_file() {
    local src="$1" dst="$2"
    [ -f "$src" ] || return 0
    same_target "$src" "$dst" && return 0
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
}

safe_sync_dir() {
    local src="$1" dst="$2"
    [ -d "$src" ] || return 0
    same_target "$src" "$dst" && return 0
    mkdir -p "$dst"
    rsync -av --delete "${EXCLUDE_ARGS[@]}" "$src/" "$dst/"
}

# 1. Sync tracked .config folders & files
if [ -d "$DOTFILES_DIR/.config" ]; then
    for repo_item in "$DOTFILES_DIR/.config"/*; do
        [ -e "$repo_item" ] || continue
        base="$(basename "$repo_item")"
        sys_item="$CONFIG_SOURCE/$base"

        if [ "$base" = "VSCodium" ] || [ "$base" = "systemd" ]; then
            continue
        fi

        if [ -d "$sys_item" ]; then
            safe_sync_dir "$sys_item" "$repo_item"
        elif [ -f "$sys_item" ]; then
            safe_copy_file "$sys_item" "$repo_item"
        fi
    done
fi

# 2. Sync systemd user units & overrides if present
safe_sync_dir "$CONFIG_SOURCE/systemd/user" "$DOTFILES_DIR/.config/systemd/user"

# 3. Sync .local/bin scripts
if [ -d "$DOTFILES_DIR/.local/bin" ]; then
    for bin_item in "$DOTFILES_DIR/.local/bin"/*; do
        [ -e "$bin_item" ] || continue
        base="$(basename "$bin_item")"
        safe_copy_file "$HOME_SOURCE/.local/bin/$base" "$bin_item"
    done
fi

# 4. Sync home dotfiles
for home_file in .zshrc .zprofile .gtkrc-2.0; do
    safe_copy_file "$HOME_SOURCE/$home_file" "$DOTFILES_DIR/$home_file"
done

# 5. Sync standalone .config files & VSCodium
for cfg_file in chromium-flags.conf brave-flags.conf pavucontrol.ini; do
    safe_copy_file "$CONFIG_SOURCE/$cfg_file" "$DOTFILES_DIR/.config/$cfg_file"
done
safe_copy_file "$CONFIG_SOURCE/VSCodium/User/settings.json" "$DOTFILES_DIR/.config/VSCodium/User/settings.json"

# 6. Sync system hardware, power, kernel & udev configs if present
mkdir -p "$DOTFILES_DIR/system/power" "$DOTFILES_DIR/system/gpu" "$DOTFILES_DIR/system/input" \
         "$DOTFILES_DIR/system/hardware" "$DOTFILES_DIR/system/sysctl" "$DOTFILES_DIR/system/boot" \
         "$DOTFILES_DIR/system/greetd" "$DOTFILES_DIR/system/systemd"

safe_copy_file "/usr/lib/systemd/system-sleep/battery-limit-rtc.sh" "$DOTFILES_DIR/system/power/battery-limit-rtc.sh"
safe_copy_file "/usr/local/bin/power-state-sync.sh" "$DOTFILES_DIR/system/power/power-state-sync.sh"
safe_copy_file "/etc/udev/rules.d/99-battery-charge-threshold.rules" "$DOTFILES_DIR/system/power/99-battery-charge-threshold.rules"
safe_copy_file "/etc/udev/rules.d/99-powersave.rules" "$DOTFILES_DIR/system/power/99-powersave.rules"
safe_copy_file "/etc/udev/rules.d/50-amd-epp.rules" "$DOTFILES_DIR/system/power/50-amd-epp.rules"
safe_copy_file "/etc/modprobe.d/asus_wmi.conf" "$DOTFILES_DIR/system/power/asus_wmi.conf"
safe_copy_file "/etc/systemd/system/asus-battery-charge-threshold.service" "$DOTFILES_DIR/system/power/asus-battery-charge-threshold.service"
safe_copy_file "/boot/acpi_override.img" "$DOTFILES_DIR/system/power/acpi_override.img"

safe_copy_file "/etc/udev/rules.d/60-amdgpu-power.rules" "$DOTFILES_DIR/system/gpu/60-amdgpu-power.rules"
safe_copy_file "/etc/modprobe.d/amdgpu.conf" "$DOTFILES_DIR/system/gpu/amdgpu.conf"
safe_copy_file "/etc/modprobe.d/supergfxd.conf" "$DOTFILES_DIR/system/gpu/supergfxd.conf"

safe_copy_file "/etc/udev/rules.d/80-uinput.rules" "$DOTFILES_DIR/system/input/80-uinput.rules"
safe_copy_file "/etc/systemd/system/asus_touchpad_numpad.service" "$DOTFILES_DIR/system/input/asus_touchpad_numpad.service"
safe_copy_file "/etc/udev/rules.d/45-stdfu-permissions.rules" "$DOTFILES_DIR/system/hardware/45-stdfu-permissions.rules"
safe_copy_file "/etc/udev/rules.d/99-flightcontroller.rules" "$DOTFILES_DIR/system/hardware/99-flightcontroller.rules"

safe_copy_file "/etc/sysctl.d/99-zram.conf" "$DOTFILES_DIR/system/sysctl/99-zram.conf"
safe_copy_file "/etc/sysctl.d/50-cursor.conf" "$DOTFILES_DIR/system/sysctl/50-cursor.conf"
safe_copy_file "/etc/systemd/resolved.conf.d/no-mdns.conf" "$DOTFILES_DIR/system/network/no-mdns.conf"
safe_copy_file "/etc/greetd/config.toml" "$DOTFILES_DIR/system/greetd/config.toml"
safe_copy_file "/etc/greetd/launch-tuigreet.sh" "$DOTFILES_DIR/system/greetd/launch-tuigreet.sh"
safe_copy_file "/etc/greetd/session-silent.sh" "$DOTFILES_DIR/system/greetd/session-silent.sh"
safe_copy_file "/etc/systemd/system/greetd.service.d/override.conf" "$DOTFILES_DIR/system/greetd/greetd-override.conf"
safe_copy_file "/etc/systemd/journald.conf.d/10-size-limit.conf" "$DOTFILES_DIR/system/systemd/10-size-limit.conf"
safe_copy_file "/etc/mkinitcpio.conf" "$DOTFILES_DIR/system/boot/mkinitcpio.conf"
safe_copy_file "/boot/loader/loader.conf" "$DOTFILES_DIR/system/boot/loader.conf"
safe_copy_file "/boot/loader/entries/2026-07-21_11-54-02_linux.conf" "$DOTFILES_DIR/system/boot/loader-linux.conf"
safe_copy_file "/boot/loader/entries/linux-lts.conf" "$DOTFILES_DIR/system/boot/loader-linux-lts.conf"

echo "========================================"
echo "✅ Sync complete! Check changes with 'git status'"
echo "========================================"
