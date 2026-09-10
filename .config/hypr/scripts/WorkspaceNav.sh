#!/usr/bin/env bash

# Workspace navigation script
# Rule:
# - Can visit an empty workspace.
# - If active workspace is empty AND next workspace is empty,
#   navigate back to previous/last visited workspace.

direction="${1:-next}"

active_ws=$(hyprctl activeworkspace -j 2>/dev/null)
curr_id=$(jq -r '.id // empty' <<< "$active_ws")
curr_windows=$(jq -r '.windows // 0' <<< "$active_ws")

# Ignore special workspaces (e.g. scratchpad with negative IDs)
if [[ -z "$curr_id" || "$curr_id" -lt 1 ]]; then
    exit 0
fi

if [[ "$direction" == "next" ]]; then
    target_id=$((curr_id + 1))

    # Check number of windows in target workspace
    target_windows=0
    if [[ "$target_id" -le 26 ]]; then
        target_windows=$(hyprctl workspaces -j 2>/dev/null | jq --argjson id "$target_id" '([.[] | select(.id == $id) | .windows] | first) // 0')
    fi

    # If current workspace is empty (0 windows) AND target workspace is also empty (0 windows):
    # Navigate to previous / last visited workspace
    if [[ "$curr_windows" -eq 0 && "$target_windows" -eq 0 ]] || [[ "$target_id" -gt 26 ]]; then
        hyprctl dispatch workspace previous
        exit 0
    fi

    hyprctl dispatch workspace "$target_id"

elif [[ "$direction" == "prev" ]]; then
    if [[ "$curr_id" -le 1 ]]; then
        exit 0
    fi
    target_id=$((curr_id - 1))
    hyprctl dispatch workspace "$target_id"
fi
