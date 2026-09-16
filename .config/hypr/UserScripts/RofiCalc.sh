#!/usr/bin/env bash
# /* ---- 💫 FiorenDot 💫 ---- */
# Author: Fioren (@Leshoraa)
# Description: Minimal calculator with auto-copy and notification feedback.
# Dependencies: qalc, rofi, wl-clipboard, libnotify

rofi_theme="$HOME/.config/rofi/config-calc.rasi"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

user_input=$(rofi -i -dmenu \
    -config "$rofi_theme" \
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
        printf "%s" "$raw_result" | wl-copy
        notify-send -i "accessories-calculator" "Calculator" "$clean_expr = $raw_result" -a "Calculator"
    else
        notify-send -u critical -i "dialog-error" "Calculator" "Invalid expression: $clean_expr" -a "Calculator"
    fi
fi
