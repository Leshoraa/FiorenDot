#!/usr/bin/env bash
# WaybarSong.sh — Media information display with smooth fade transitions for Waybar
MODE="$1"
MANUAL_PAUSE="/tmp/waybar_manual_pause"

if [[ "$MODE" == "--toggle" ]]; then
    if [[ "$(playerctl status 2>/dev/null)" == "Playing" ]]; then
        touch "$MANUAL_PAUSE"
    else
        rm -f "$MANUAL_PAUSE"
    fi
    playerctl play-pause
    exit 0
fi

trap 'exit 0' SIGINT SIGTERM SIGHUP

last_text=""
was_visible=false
format_str="{{status}}|{{markup_escape(title)}}|{{markup_escape(artist)}}"

while true; do
    playerctl -a metadata --format "$format_str" -F 2>/dev/null | while IFS="|" read -r status title artist; do
        should_show=false
        if [[ "$status" == "Playing" ]] || ([[ "$status" == "Paused" ]] && [[ -f "$MANUAL_PAUSE" ]]); then
            should_show=true
        fi

        if $should_show; then
            case "$MODE" in
                --title)
                    [[ ${#title} -gt 26 ]] && title="${title:0:22}..."
                    cur_text="$title"
                    ;;
                --sep)
                    cur_text="-"
                    ;;
                --artist)
                    cur_text="$artist"
                    ;;
                *)
                    cur_text="$title"
                    ;;
            esac

            if ! $was_visible; then
                # Smooth fade-in: start at opacity 0 then animate to full
                echo "{\"text\": \"$cur_text\", \"class\": \"$status starting\"}"
                sleep 0.05
                echo "{\"text\": \"$cur_text\", \"class\": \"$status\"}"
                was_visible=true
            else
                echo "{\"text\": \"$cur_text\", \"class\": \"$status\"}"
            fi
            last_text="$cur_text"
        else
            if $was_visible && [[ -n "$last_text" ]]; then
                # Smooth fade-out: animate to opacity 0 before clearing
                echo "{\"text\": \"$last_text\", \"class\": \"fading\"}"
                sleep 0.35
                was_visible=false
                last_text=""
            fi
            echo "{\"text\": \"\"}"
        fi
    done

    # If playerctl exited (e.g. media player closed)
    if $was_visible && [[ -n "$last_text" ]]; then
        echo "{\"text\": \"$last_text\", \"class\": \"fading\"}"
        sleep 0.35
        was_visible=false
        last_text=""
    fi
    echo "{\"text\": \"\"}"
    sleep 1
done
