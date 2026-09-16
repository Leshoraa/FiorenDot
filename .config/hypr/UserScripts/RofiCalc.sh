#!/usr/bin/env bash
# /* ---- 💫 FiorenDot 💫 ---- */
# Author: Fioren (@Leshoraa)
# Description: Minimal calculator with auto-copy and notification feedback.
# Dependencies: qalc, rofi, wl-clipboard, libnotify

rofi_theme="$HOME/.config/rofi/config-calc.rasi"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

calc_result=""
last_expr=""

while true; do
    if [ -n "$calc_result" ]; then
        mesg_text=" 󰃬  <b>$last_expr</b> = <b>$calc_result</b>  <i>(Copied)</i>"
    else
        mesg_text=" 󰃬  Enter calculation (e.g. 25 * 4, 15% * 250, sqrt(144))"
    fi

    user_input=$(rofi -i -dmenu \
        -config "$rofi_theme" \
        -mesg "$mesg_text" \
        -p "Calc" </dev/null
    )

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
            notify-send -i "accessories-calculator" "Calculator" "$last_expr = $calc_result (Copied)" -a "Calculator"
        else
            calc_result=""
            last_expr=""
            notify-send -u critical -i "dialog-error" "Calculator" "Invalid expression: $clean_expr" -a "Calculator"
        fi
    fi
done
