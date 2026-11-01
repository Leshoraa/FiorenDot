#!/usr/bin/env bash
# FiorenDot - Bluetooth Manager & SwayNC Toggle Script
# Author: Fioren (@Leshoraa)

get_status() {
    if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
        echo "false"
        return
    fi
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "true"
    else
        echo "false"
    fi
}

cmd_on() {
    # 1. Unblock rfkill if blocked
    rfkill unblock bluetooth 2>/dev/null || true
    sleep 0.3

    # 2. Power on bluetooth adapter
    bluetoothctl power on >/dev/null 2>&1 || true

    # 3. Desktop feedback notification
    notify-send -e -u low -h string:x-canonical-private-synchronous:bluetooth_notif \
        -h boolean:SWAYNC_BYPASS_DND:true "Bluetooth" "Enabled"

    # 4. Close SwayNC control center so the device manager window is visible
    swaync-client -cp 2>/dev/null || true

    # 5. Open blueman-manager so user can select and connect to devices
    if command -v blueman-manager >/dev/null 2>&1; then
        (sleep 0.2 && blueman-manager) >/dev/null 2>&1 &
    fi

    # 6. Sync SwayNC button state if called externally
    if [[ -z "${SWAYNC_TOGGLE_STATE:-}" ]]; then
        (sleep 0.2 && swaync-client -R 2>/dev/null) &
    fi
}

cmd_off() {
    # 1. Close blueman-manager if open
    pkill -x blueman-manager 2>/dev/null || true

    # 2. Power off bluetooth adapter
    bluetoothctl power off >/dev/null 2>&1 || true

    # 3. Block via rfkill for power saving
    rfkill block bluetooth 2>/dev/null || true

    # 4. Desktop feedback notification
    notify-send -e -u low -h string:x-canonical-private-synchronous:bluetooth_notif \
        -h boolean:SWAYNC_BYPASS_DND:true "Bluetooth" "Disabled"

    # 5. Sync SwayNC button state if called externally
    if [[ -z "${SWAYNC_TOGGLE_STATE:-}" ]]; then
        (sleep 0.2 && swaync-client -R 2>/dev/null) &
    fi
}

cmd_toggle() {
    if [[ -n "${SWAYNC_TOGGLE_STATE:-}" ]]; then
        if [[ "$SWAYNC_TOGGLE_STATE" == "true" ]]; then
            cmd_on
        else
            cmd_off
        fi
    else
        local status
        status=$(get_status)
        if [[ "$status" == "true" ]]; then
            cmd_off
        else
            cmd_on
        fi
    fi
}

cmd_menu() {
    rfkill unblock bluetooth 2>/dev/null || true
    bluetoothctl power on >/dev/null 2>&1 || true
    swaync-client -cp 2>/dev/null || true
    if command -v blueman-manager >/dev/null 2>&1; then
        blueman-manager >/dev/null 2>&1 &
    fi
}

case "$1" in
    status)
        get_status
        ;;
    on)
        cmd_on
        ;;
    off)
        cmd_off
        ;;
    toggle)
        cmd_toggle
        ;;
    menu)
        cmd_menu
        ;;
    *)
        echo "Usage: $0 {status|toggle|on|off|menu}"
        exit 1
        ;;
esac
