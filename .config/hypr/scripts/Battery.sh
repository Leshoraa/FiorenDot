#!/usr/bin/env bash

# If called with --notify or --daemon, delegate to the unified battery management daemon
if [ "$1" = "--notify" ] || [ "$1" = "--daemon" ]; then
    exec "$HOME/.config/hypr/scripts/BatteryLimitToggle.sh" daemon
fi

# Default: Output icon and capacity for Hyprlock (instant exit)
for bat_cap in /sys/class/power_supply/BAT*/capacity; do
    if [ -f "$bat_cap" ]; then
        bat_dir=$(dirname "$bat_cap")
        battery_status=$(cat "$bat_dir/status" 2>/dev/null)
        battery_capacity=$(cat "$bat_cap" 2>/dev/null)

        icon="󰁹"
        if [ "$battery_status" = "Charging" ]; then
            icon="󰂄"
        elif [ "$battery_capacity" -le 20 ]; then
            icon="󰂃"
        elif [ "$battery_capacity" -le 50 ]; then
            icon="󰁾"
        fi

        echo "$icon $battery_capacity%"
        exit 0
    fi
done

echo ""