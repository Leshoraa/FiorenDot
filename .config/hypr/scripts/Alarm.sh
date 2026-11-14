#!/usr/bin/env bash
# ==============================================================================
# Mini Alarm & Timer Daemon for Waybar & Quickshell
# Author: Antigravity & Fioren (@Leshoraa)
# ==============================================================================

STATE_FILE="/tmp/waybar_alarm.json"
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
ALARM_PID_FILE="/tmp/waybar_alarm_sound.pid"
QS_ALARM_DIR="$HOME/.config/quickshell/alarm"

get_now() {
    date +%s
}

read_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" 2>/dev/null
    else
        echo '{"status":"idle","target":0,"total":0}'
    fi
}

write_state() {
    local status="$1"
    local target="${2:-0}"
    local total="${3:-0}"
    cat <<EOF > "$STATE_FILE"
{"status":"$status","target":$target,"total":$total}
EOF
}

format_time() {
    local secs=$1
    if [ "$secs" -lt 0 ]; then
        secs=0
    fi
    local h=$((secs / 3600))
    local m=$(((secs % 3600) / 60))
    local s=$((secs % 60))
    if [ "$h" -gt 0 ]; then
        printf "%02d:%02d:%02d" "$h" "$m" "$s"
    else
        printf "%02d:%02d" "$m" "$s"
    fi
}

format_human() {
    local secs=$1
    if [ "$secs" -lt 0 ]; then
        secs=0
    fi
    local h=$((secs / 3600))
    local m=$(((secs % 3600) / 60))
    local s=$((secs % 60))
    if [ "$h" -gt 0 ]; then
        echo "${h}h ${m}m ${s}s"
    elif [ "$m" -gt 0 ]; then
        echo "${m}m ${s}s"
    else
        echo "${s}s"
    fi
}

play_sound_loop() {
    (
        while [ -f "$ALARM_PID_FILE" ]; do
            if command -v pw-play >/dev/null 2>&1; then
                pw-play "$SOUND_FILE" 2>/dev/null
            elif command -v paplay >/dev/null 2>&1; then
                paplay "$SOUND_FILE" 2>/dev/null
            fi
            sleep 0.8
        done
    ) &
    echo $! > "$ALARM_PID_FILE"
}

stop_sound() {
    if [ -f "$ALARM_PID_FILE" ]; then
        local pid
        pid=$(cat "$ALARM_PID_FILE" 2>/dev/null)
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
            pkill -P "$pid" 2>/dev/null || true
        fi
        rm -f "$ALARM_PID_FILE" 2>/dev/null || true
    fi
    pkill -f "alarm-clock-elapsed" 2>/dev/null || true
}

ring_alarm() {
    write_state "ringing" 0 0
    play_sound_loop

    # Send desktop notification in background without blocking caller
    if command -v notify-send >/dev/null 2>&1; then
        (
            ACTION=$(notify-send -u critical -a "Alarm" \
                -i "alarm" \
                -h string:x-canonical-private-synchronous:minialarm \
                "Alarm" "Alarm is ringing!" \
                --action="stop=Stop Alarm" 2>/dev/null)
            if [ "$ACTION" = "stop" ]; then
                /home/fioren/.config/hypr/scripts/Alarm.sh stop
            fi
        ) >/dev/null 2>&1 &
    fi
}

start_timer() {
    local duration=$1
    if [ -z "$duration" ] || [ "$duration" -le 0 ]; then
        return 1
    fi
    stop_sound
    local now
    now=$(get_now)
    local target=$((now + duration))
    write_state "running" "$target" "$duration"

    # Background watchdog to trigger ring when time elapses
    (
        while true; do
            sleep 1
            local curr_state
            curr_state=$(read_state)
            local st
            st=$(echo "$curr_state" | jq -r '.status // "idle"')
            if [ "$st" != "running" ]; then
                exit 0
            fi
            local tgt
            tgt=$(echo "$curr_state" | jq -r '.target // 0')
            local cur
            cur=$(get_now)
            if [ "$cur" -ge "$tgt" ]; then
                ring_alarm
                exit 0
            fi
        done
    ) >/dev/null 2>&1 &
}

add_time() {
    local extra=${1:-60}
    local curr_state
    curr_state=$(read_state)
    local st
    st=$(echo "$curr_state" | jq -r '.status // "idle"')
    local tgt
    tgt=$(echo "$curr_state" | jq -r '.target // 0')
    local tot
    tot=$(echo "$curr_state" | jq -r '.total // 0')

    if [ "$st" = "running" ] && [ "$tgt" -gt 0 ]; then
        local new_target=$((tgt + extra))
        local new_total=$((tot + extra))
        write_state "running" "$new_target" "$new_total"
    else
        start_timer "$extra"
    fi
}

stop_alarm() {
    stop_sound
    write_state "idle" 0 0
}

toggle_ui() {
    if pgrep -f "qs.*alarm" >/dev/null || pgrep -f "quickshell.*alarm" >/dev/null; then
        pkill -f "qs.*alarm" 2>/dev/null || true
        pkill -f "quickshell.*alarm" 2>/dev/null || true
    else
        qs -p "$QS_ALARM_DIR" >/dev/null 2>&1 &
    fi
}

get_waybar_status() {
    local mode="${1:-bar}"
    local curr_state
    curr_state=$(read_state)
    local st
    st=$(echo "$curr_state" | jq -r '.status // "idle"')
    local tgt
    tgt=$(echo "$curr_state" | jq -r '.target // 0')
    local tot
    tot=$(echo "$curr_state" | jq -r '.total // 0')

    if [ "$st" = "running" ]; then
        local now
        now=$(get_now)
        local remaining=$((tgt - now))
        if [ "$remaining" -le 0 ]; then
            if [ "$st" != "ringing" ]; then
                ring_alarm
            fi
            if [ "$mode" = "drawer" ]; then
                echo '{"text": ""}'
            else
                echo '{"text": "󰂞 00:00", "tooltip": "Alarm is ringing!\nRight-click: Stop", "class": "ringing"}'
            fi
        else
            if [ "$mode" = "drawer" ]; then
                echo '{"text": ""}'
            else
                local formatted
                formatted=$(format_time "$remaining")
                local human
                human=$(format_human "$remaining")
                echo "{\"text\": \"󰀠 $formatted\", \"tooltip\": \"Alarm: $human left\\nLeft: Open | Right: Stop\", \"class\": \"running\"}"
            fi
        fi
    elif [ "$st" = "ringing" ]; then
        if [ "$mode" = "drawer" ]; then
            echo '{"text": ""}'
        else
            echo '{"text": "󰂞 00:00", "tooltip": "Alarm is ringing!\nRight-click: Stop", "class": "ringing"}'
        fi
    else
        # idle
        if [ "$mode" = "drawer" ]; then
            echo '{"text": "󰀠", "tooltip": "Alarm", "class": "idle"}'
        else
            echo '{"text": ""}'
        fi
    fi
}

get_json_state() {
    local curr_state
    curr_state=$(read_state)
    local st
    st=$(echo "$curr_state" | jq -r '.status // "idle"')
    local tgt
    tgt=$(echo "$curr_state" | jq -r '.target // 0')
    local tot
    tot=$(echo "$curr_state" | jq -r '.total // 0')
    local now
    now=$(get_now)
    local remaining=0
    if [ "$st" = "running" ]; then
        remaining=$((tgt - now))
        if [ "$remaining" -lt 0 ]; then remaining=0; fi
    fi
    local formatted
    formatted=$(format_time "$remaining")
    cat <<EOF
{"status":"$st","remaining":$remaining,"total":$tot,"formatted":"$formatted"}
EOF
}

case "$1" in
    status)
        get_waybar_status "$2"
        ;;
    json)
        get_json_state
        ;;
    start)
        start_timer "$2"
        ;;
    add)
        add_time "${2:-60}"
        ;;
    stop)
        stop_alarm
        ;;
    toggle-ui)
        toggle_ui
        ;;
    open-ui)
        if ! pgrep -f "qs.*alarm" >/dev/null; then
            qs -p "$QS_ALARM_DIR" >/dev/null 2>&1 &
        fi
        ;;
    close-ui)
        pkill -f "qs.*alarm" 2>/dev/null || true
        pkill -f "quickshell.*alarm" 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {status|json|start <secs>|add <secs>|stop|toggle-ui|open-ui|close-ui}"
        exit 1
        ;;
esac
