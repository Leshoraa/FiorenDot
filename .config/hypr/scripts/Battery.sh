#!/usr/bin/env bash

NOTIFIED_15=false

while true; do
    for i in {0..3}; do
        if [ -f /sys/class/power_supply/BAT$i/capacity ]; then
            battery_status=$(cat /sys/class/power_supply/BAT$i/status)
            battery_capacity=$(cat /sys/class/power_supply/BAT$i/capacity)

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