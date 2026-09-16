#!/usr/bin/env bash
# /* ---- 💫 FiorenDot - ASUS Vivobook S 14 Flip 💫 ---- */
# Author: Fioren (@Leshoraa)
# Description: Smart Rofi Calculator with history tape, auto-copy & notification.
# Dependencies: qalc (libqalculate), rofi, wl-clipboard, libnotify

rofi_theme="$HOME/.config/rofi/config-calc.rasi"
HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/rofi_calc_history"

# Pastikan direktori cache ada
mkdir -p "$(dirname "$HIST_FILE")"
touch "$HIST_FILE"

# Tutup rofi jika sudah berjalan
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

calc_result=""
last_expr=""

while true; do
    # Tentukan pesan status / feedback
    if [ -n "$calc_result" ]; then
        mesg_text="   <b>$last_expr</b> = <b>$calc_result</b>  <i>(Tersalin!)</i>"
    else
        mesg_text="   Ketik perhitungan (misal: 25 * 4, 15% * 2500, sqrt(144))"
    fi

    # Baca riwayat (maksimal 10 perhitungan terakhir, terbaru di atas)
    history_entries=""
    if [ -s "$HIST_FILE" ]; then
        history_entries=$(tac "$HIST_FILE" | head -n 10)
    fi

    # Jalankan rofi
    user_input=$(echo "$history_entries" | rofi -i -dmenu \
        -config "$rofi_theme" \
        -mesg "$mesg_text" \
        -p "Calc"
    )

    exit_code=$?
    if [ $exit_code -ne 0 ] || [ -z "$user_input" ]; then
        exit 0
    fi

    # Jika user mengklik / memilih entri riwayat (format: "󰃬 <expr> = <hasil>")
    if [[ "$user_input" =~ ^󰃬.*=.* ]]; then
        selected_val=$(echo "$user_input" | sed -e 's/.*=[[:space:]]*//' -e 's/[[:space:]]*$//')
        printf "%s" "$selected_val" | wl-copy
        notify-send -i "accessories-calculator" "Kalkulator Disalin" "Hasil riwayat disalin: $selected_val" -a "FiorenDot Calc"
        calc_result="$selected_val"
        last_expr="Riwayat"
        continue
    fi

    # Jika user mengetik ekspresi baru
    clean_expr=$(echo "$user_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ -n "$clean_expr" ]; then
        raw_result=$(qalc -t "$clean_expr" 2>&1)
        calc_status=$?

        if [ $calc_status -eq 0 ] && [ -n "$raw_result" ]; then
            calc_result="$raw_result"
            last_expr="$clean_expr"

            # Salin ke clipboard
            printf "%s" "$calc_result" | wl-copy

            # Simpan ke riwayat (hindari duplikasi berurutan)
            new_entry="󰃬  $last_expr = $calc_result"
            if ! grep -Fxq "$new_entry" "$HIST_FILE" 2>/dev/null; then
                echo "$new_entry" >> "$HIST_FILE"
            fi

            notify-send -i "accessories-calculator" "Kalkulator Disalin" "$last_expr = $calc_result" -a "FiorenDot Calc"
        else
            calc_result="Error"
            last_expr="$clean_expr"
            notify-send -u critical -i "dialog-error" "Kalkulator Error" "Operasi tidak valid: $clean_expr" -a "FiorenDot Calc"
        fi
    fi
done
