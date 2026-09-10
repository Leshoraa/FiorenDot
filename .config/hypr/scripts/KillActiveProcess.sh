#!/usr/bin/env bash

set -u

# Ambil informasi window aktif
active_window=$(hyprctl activewindow -j)

address=$(jq -r '.address' <<< "$active_window")
pid=$(jq -r '.pid' <<< "$active_window")

# Pastikan data valid
if [[ -z "$address" || "$address" == "null" ]]; then
    exit 0
fi

if [[ -z "$pid" || "$pid" == "null" || "$pid" == "0" ]]; then
    hyprctl dispatch closewindow "address:$address"
    exit 0
fi

# Tutup HANYA window yang sedang aktif
hyprctl dispatch closewindow "address:$address"

# Beri Hyprland waktu memproses penutupan window
sleep 0.2

# Cek apakah masih ada window lain dari PID yang sama
remaining=$(hyprctl clients -j | jq --arg pid "$pid" '
    [.[] | select(.pid == ($pid | tonumber))] | length
')

# Kalau sudah tidak ada window dari PID tersebut,
# matikan proses utama agar aplikasi benar-benar 종료
if [[ "$remaining" -eq 0 ]]; then
    kill "$pid" 2>/dev/null
fi