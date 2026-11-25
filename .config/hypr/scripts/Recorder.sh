#!/bin/bash

SAVE_DIR="$HOME/Videos"
mkdir -p "$SAVE_DIR"

FILENAME="recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Toggle gpu-screen-recorder
if pkill -f -INT gpu-screen-recorder; then
    notify-send -e -u low -i "$ICON" "Screen Recorder" "Recording stopped"
else
    notify-send -e -u low -i "$ICON" "Screen Recorder" "Recording started"
    # Fullscreen @ 60 FPS with default sink audio
    gpu-screen-recorder -w screen -f 60 -a "$(pactl get-default-sink).monitor" -o "$SAVE_DIR/$FILENAME" &
fi