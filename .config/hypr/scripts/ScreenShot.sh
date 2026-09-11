#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Screenshots scripts - MODIFIED: No Sound & Faster + Auto Save (No Icon)

# variables
time=$(date "+%d-%b_%H-%M-%S")
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

sDIR="$HOME/.config/hypr/scripts"

active_window_class=$(hyprctl -j activewindow 2>/dev/null | jq -r '(.class // "window")')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

notify_cmd_base="notify-send -t 2200 -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} "
notify_cmd_shot_win="${notify_cmd_base} "
notify_cmd_NOT="notify-send -u low "

# notify and view screenshot
notify_view() {
    if [[ "$1" == "active" ]]; then
        if [[ -e "${active_window_path}" ]]; then
            ${notify_cmd_shot_win} "Screenshot of:" "${active_window_class} Saved."
        else
            ${notify_cmd_NOT} "Screenshot of:" "${active_window_class} NOT Saved."
        fi
    else
        local check_file="${dir}/${file}"
        if [[ -e "$check_file" ]]; then
            ${notify_cmd_shot} "Screenshot" "Saved & Copied to Clipboard"
        else
            ${notify_cmd_NOT} "Screenshot" "NOT Saved"
        fi
    fi
}

# countdown
countdown() {
    for sec in $(seq $1 -1 1); do
        notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 "Taking shot" "in: $sec secs"
        sleep 1
    done
}

# take shots
shotnow() {
    cd "${dir}" && grim - | tee "$file" | wl-copy
    notify_view
}

shot5() {
    countdown '5'
    cd "${dir}" && grim - | tee "$file" | wl-copy
    notify_view
}

shot10() {
    countdown '10'
    cd "${dir}" && grim - | tee "$file" | wl-copy
    notify_view
}

shotwin() {
    w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
    w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
    cd "${dir}" && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
    notify_view
}

shotarea() {
    local target="${dir}/${file}"
    local area
    area=$(slurp 2>/dev/null) || return 0
    if [[ -n "$area" ]]; then
        if grim -g "$area" "$target"; then
            if [[ -s "$target" ]]; then
                wl-copy < "$target"
                notify_view
            else
                rm -f "$target"
            fi
        fi
    fi
}

shotactive() {
    active_window_class=$(hyprctl -j activewindow 2>/dev/null | jq -r '(.class // "window")')
    active_window_file="Screenshot_${time}_${active_window_class}.png"
    active_window_path="${dir}/${active_window_file}"

    hyprctl -j activewindow 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${active_window_path}"
    if [[ -s "${active_window_path}" ]]; then
        wl-copy < "${active_window_path}"
    fi
    notify_view "active"
}

shotswappy() {
    # Crop screenshot: autosave to Screenshots folder AND copy to clipboard
    shotarea
}

if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
    shotnow
elif [[ "$1" == "--in5" ]]; then
    shot5
elif [[ "$1" == "--in10" ]]; then
    shot10
elif [[ "$1" == "--win" ]]; then
    shotwin
elif [[ "$1" == "--area" ]]; then
    shotarea
elif [[ "$1" == "--active" ]]; then
    shotactive
elif [[ "$1" == "--swappy" ]]; then
    shotswappy
else
    echo -e "Available Options : --now --in5 --in10 --win --area --active --swappy"
fi

exit 0
