#!/usr/bin/env bash

#ICON_DIRECTORY="$HOME/.config/swaync/icons"

fetch_volume_status() {
    pamixer --get-volume
}

fetch_mute_status() {
    pamixer --get-mute
}

fetch_icon_path() {
    local volume_level=$(fetch_volume_status)
    local is_muted=$(fetch_mute_status)

    if [[ "$is_muted" == "true" || "$volume_level" -eq 0 ]]; then
        echo "$ICON_DIRECTORY/volume-mute.png"
    elif [[ "$volume_level" -le 30 ]]; then
        echo "$ICON_DIRECTORY/volume-low.png"
    elif [[ "$volume_level" -le 60 ]]; then
        echo "$ICON_DIRECTORY/volume-mid.png"
    else
        echo "$ICON_DIRECTORY/volume-high.png"
    fi
}

dispatch_notification() {
    local volume=$(fetch_volume_status)
    local icon=$(fetch_icon_path)
    local is_muted=$(fetch_mute_status)

    if [[ "$is_muted" == "true" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon" "Volume" "Muted"
    else
        notify-send -e -h int:value:"$volume" -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon" "Volume Level: $volume%"
    fi
}

increase_volume() {
    pamixer -u && pamixer -i 1 --allow-boost --set-limit 150 && dispatch_notification
}

decrease_volume() {
    pamixer -u && pamixer -d 1 && dispatch_notification
}

toggle_audio_mute() {
    pamixer -t && dispatch_notification
}

toggle_microphone_mute() {
    pamixer --default-source -t
    local mic_status=$(pamixer --default-source --get-mute)
    local mic_icon="$ICON_DIRECTORY/microphone.png"
    [[ "$mic_status" == "true" ]] && mic_icon="$ICON_DIRECTORY/microphone-mute.png"
    
    notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$mic_icon" "Microphone" "Status Toggled"
}

case "$1" in
    --inc) increase_volume ;;
    --dec) decrease_volume ;;
    --toggle) toggle_audio_mute ;;
    --toggle-mic) toggle_microphone_mute ;;
    --get) fetch_volume_status ;;
    *) fetch_volume_status ;;
esac