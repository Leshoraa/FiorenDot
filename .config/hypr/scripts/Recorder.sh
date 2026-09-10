#!/bin/bash

# Folder tempat menyimpan video
SAVE_DIR="$HOME/Videos"
# Pastikan folder ada
mkdir -p "$SAVE_DIR"

# Nama file dengan timestamp
FILENAME="rekaman_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Cek apakah gpu-screen-recorder sedang berjalan
if pkill -f -INT gpu-screen-recorder; then
    # Jika berhasil di-stop (pkill exit code 0)
    notify-send -e -u low -i "$ICON" "Screen Recorder" "Stopping Record"
else
    # Jika tidak ada proses yang berjalan, maka mulai rekam
    notify-send -e -u low -i "$ICON" "Screen Recorder" "Starting Recorder"
    
    # Jalankan perekaman di background
    # -w screen: rekam seluruh layar
    # -f 60: 60 FPS
    # -a: audio dari default sink
    gpu-screen-recorder -w screen -f 60 -a "$(pactl get-default-sink).monitor" -o "$SAVE_DIR/$FILENAME" &
fi