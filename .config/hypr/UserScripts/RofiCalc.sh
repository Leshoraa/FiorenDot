#!/usr/bin/env bash
# FiorenDot - Calculator
# Author: Fioren (@Leshoraa)

rofi_theme="$HOME/.config/rofi/config-calc.rasi"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

calc_result=""
last_expr=""

while true; do
    rofi_args=(-i -dmenu -config "$rofi_theme" -p "Calc")

    if [ -n "$calc_result" ]; then
        rofi_args+=(-mesg "󰃬  <b>$last_expr</b> = <b>$calc_result</b>")
    fi

    user_input=$(rofi "${rofi_args[@]}" </dev/null)
    exit_code=$?

    if [ $exit_code -ne 0 ] || [ -z "$user_input" ]; then
        exit 0
    fi

    clean_expr=$(echo "$user_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ -n "$clean_expr" ]; then
        raw_result=$(qalc -t "$clean_expr" 2>&1)
        calc_status=$?

        if [ $calc_status -eq 0 ] && [ -n "$raw_result" ]; then
            calc_result="$raw_result"
            last_expr="$clean_expr"
            printf "%s" "$calc_result" | wl-copy
        else
            calc_result="Error"
            last_expr="$clean_expr"
        fi
    fi
done
