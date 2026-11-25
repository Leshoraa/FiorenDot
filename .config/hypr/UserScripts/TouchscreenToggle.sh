#!/usr/bin/env bash
# ==============================================================================
# Touchscreen Toggle (Hyprland + Gestures Daemon)
# Rootless instant toggle to prevent palm/phantom input and save battery
# ==============================================================================

STATUS_FILE="${XDG_RUNTIME_DIR:-/tmp}/touchscreen.status"
NOTIF_ICON="input-touchscreen"

# Read current state (default: disabled on boot)
is_enabled() {
    if [ -f "$STATUS_FILE" ]; then
        [ "$(cat "$STATUS_FILE")" = "enabled" ]
    else
        return 1
    fi
}

disable_touchscreen() {
    # 1. Stop background gestures daemon to save CPU/battery
    systemctl --user stop touchscreen-gestures.service 2>/dev/null || true

    # 2. Disable touchscreen & stylus devices in Hyprland
    hyprctl eval "hl.device({ name = 'wdht1f01:00-2575:0911', enabled = false }); hl.device({ name = 'wdht1f01:00-2575:0911-stylus', enabled = false }); hl.config({ input = { touchdevice = { enabled = false } } })" >/dev/null 2>&1

    echo "disabled" > "$STATUS_FILE"
    notify-send -u low -i "$NOTIF_ICON" "Touchscreen" "Disabled"
}

enable_touchscreen() {
    # 1. Re-bind i2c_hid_acpi kernel module if unbound and passwordless sudo allows
    if [ ! -d "/sys/bus/i2c/drivers/i2c_hid_acpi/i2c-WDHT1F01:00" ]; then
        sudo -n modprobe -r i2c_hid_acpi 2>/dev/null && sudo -n modprobe i2c_hid_acpi 2>/dev/null
        sleep 0.5
    fi

    # 2. Re-enable touchscreen & stylus devices in Hyprland
    hyprctl eval "hl.device({ name = 'wdht1f01:00-2575:0911', enabled = true }); hl.device({ name = 'wdht1f01:00-2575:0911-stylus', enabled = true }); hl.config({ input = { touchdevice = { enabled = true } } })" >/dev/null 2>&1

    # 3. Restart gestures daemon
    systemctl --user start touchscreen-gestures.service 2>/dev/null || true

    echo "enabled" > "$STATUS_FILE"
    notify-send -u low -i "$NOTIF_ICON" "Touchscreen" "Enabled"
}

case "$1" in
    disable)
        disable_touchscreen
        ;;
    enable)
        enable_touchscreen
        ;;
    status)
        if is_enabled; then
            echo "enabled"
        else
            echo "disabled"
        fi
        ;;
    toggle|*)
        if is_enabled; then
            disable_touchscreen
        else
            enable_touchscreen
        fi
        ;;
esac
