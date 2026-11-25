#!/usr/bin/env bash

set -u

# Query active window
active_window=$(hyprctl activewindow -j)

address=$(jq -r '.address' <<< "$active_window")
pid=$(jq -r '.pid' <<< "$active_window")

# Exit if missing window metadata
if [[ -z "$address" || "$address" == "null" ]]; then
    exit 0
fi

if [[ -z "$pid" || "$pid" == "null" || "$pid" == "0" ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'address:$address' }))" >/dev/null
    exit 0
fi

# Close active window only
hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'address:$address' }))" >/dev/null

# Wait for compositor window close
sleep 0.2

# Check if any windows remain for this PID
remaining=$(hyprctl clients -j | jq --arg pid "$pid" '
    [.[] | select(.pid == ($pid | tonumber))] | length
')

# Kill main process once its last window closes
if [[ "$remaining" -eq 0 ]]; then
    kill "$pid" 2>/dev/null
fi