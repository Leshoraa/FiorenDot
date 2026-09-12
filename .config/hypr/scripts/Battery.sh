#!/usr/bin/env bash

NOTIFIED_15=false

while true; do
    for bat_cap in /sys/class/power_supply/BAT*/capacity; do
        if [ -f "$bat_cap" ]; then
            bat_dir=$(dirname "$bat_cap")
            battery_status=$(cat "$bat_dir/status")
            battery_capacity=$(cat "$bat_cap")

            if [ "$battery_status" = "Discharging" ]; then
                if [ "$battery_capacity" -le 15 ] && [ "$NOTIFIED_15" = false ]; then
                    notify-send -u critical -a "System" "Low Battery!" "Battery level is at $battery_capacity%."
                    NOTIFIED_15=true
                fi
            elif [ "$battery_status" = "Charging" ] || [ "$battery_status" = "Full" ]; then
                NOTIFIED_15=false
            fi
        fi
    done
    
    sleep 60
done