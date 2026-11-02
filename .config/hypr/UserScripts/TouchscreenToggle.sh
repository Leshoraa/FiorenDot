#!/usr/bin/env bash
# ==============================================================================
# Touchscreen Toggle (Hyprland + Gestures Daemon)
# Aman, instan, tidak butuh root, dan mencegah sentuhan tembus / boros baterai
# ==============================================================================

STATUS_FILE="${XDG_RUNTIME_DIR:-/tmp}/touchscreen.status"
NOTIF_ICON="input-touchscreen"

# Cek status saat ini (default: disabled sejak boot jika file belum ada)
is_enabled() {
    if [ -f "$STATUS_FILE" ]; then
        [ "$(cat "$STATUS_FILE")" = "enabled" ]
    else
        return 1
    fi
}

disable_touchscreen() {
    # 1. Hentikan daemon background gestures agar tidak mem-poll /dev/input dan hemat CPU/baterai
    systemctl --user stop touchscreen-gestures.service 2>/dev/null || true

    # 2. Nonaktifkan layar sentuh jari dan stylus di Hyprland
    hyprctl keyword "device[wdht1f01:00-2575:0911]:enabled" false >/dev/null 2>&1
    hyprctl keyword "device[wdht1f01:00-2575:0911-stylus]:enabled" false >/dev/null 2>&1
    hyprctl keyword "input:touchdevice:enabled" false >/dev/null 2>&1

    echo "disabled" > "$STATUS_FILE"
    notify-send -u low -i "$NOTIF_ICON" "Touchscreen" "Disabled"
}

enable_touchscreen() {
    # 1. Jika driver i2c di level kernel sempat ter-unbind, coba panggil modprobe jika sudo diizinkan
    if [ ! -d "/sys/bus/i2c/drivers/i2c_hid_acpi/i2c-WDHT1F01:00" ]; then
        sudo -n modprobe -r i2c_hid_acpi 2>/dev/null && sudo -n modprobe i2c_hid_acpi 2>/dev/null
        sleep 0.5
    fi

    # 2. Aktifkan kembali layar sentuh jari dan stylus di Hyprland
    hyprctl keyword "device[wdht1f01:00-2575:0911]:enabled" true >/dev/null 2>&1
    hyprctl keyword "device[wdht1f01:00-2575:0911-stylus]:enabled" true >/dev/null 2>&1
    hyprctl keyword "input:touchdevice:enabled" true >/dev/null 2>&1

    # 3. Jalankan kembali daemon background gestures
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
