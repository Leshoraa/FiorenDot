#!/usr/bin/env bash

# Workspace navigation script
# Rule:
# - Can visit an empty workspace.
# - If active workspace is empty:
#   - If there is an occupied workspace ahead (for next) or behind (for prev), jump to it!
#   - If there are NO more occupied workspaces in that direction, navigate back to previous/last visited workspace.

direction="${1:-next}"

active_ws=$(hyprctl activeworkspace -j 2>/dev/null)
curr_id=$(jq -r '.id // empty' <<< "$active_ws")
curr_windows=$(jq -r '.windows // 0' <<< "$active_ws")

# Ignore special workspaces (e.g. scratchpad with negative IDs)
if [[ -z "$curr_id" || "$curr_id" -lt 1 ]]; then
    exit 0
fi

workspaces_json=$(hyprctl workspaces -j 2>/dev/null)

if [[ "$direction" == "next" ]]; then
    if [[ "$curr_windows" -eq 0 ]]; then
        # Currently on an empty workspace.
        # Find the next workspace with windows > 0 that has ID > curr_id
        next_occupied=$(jq --argjson curr "$curr_id" '
            [.[] | select(.id > $curr and .windows > 0) | .id] | sort | first // empty
        ' <<< "$workspaces_json")

        if [[ -n "$next_occupied" ]]; then
            # Jump directly to the next occupied workspace (e.g. from D to J)
            hyprctl dispatch workspace "$next_occupied"
            exit 0
        else
            # No occupied workspace ahead and current is empty -> go back to previous
            hyprctl dispatch workspace previous
            exit 0
        fi
    else
        # Currently on an occupied workspace.
        target_id=$((curr_id + 1))
        if [[ "$target_id" -gt 26 ]]; then
            hyprctl dispatch workspace previous
            exit 0
        fi
        hyprctl dispatch workspace "$target_id"
        exit 0
    fi

elif [[ "$direction" == "prev" ]]; then
    if [[ "$curr_windows" -eq 0 ]]; then
        # Currently on an empty workspace.
        # Find the previous workspace with windows > 0 that has ID < curr_id
        prev_occupied=$(jq --argjson curr "$curr_id" '
            [.[] | select(.id < $curr and .id >= 1 and .windows > 0) | .id] | sort | last // empty
        ' <<< "$workspaces_json")

        if [[ -n "$prev_occupied" ]]; then
            # Jump directly to the previous occupied workspace
            hyprctl dispatch workspace "$prev_occupied"
            exit 0
        else
            # No occupied workspace behind and current is empty -> go back to previous
            if [[ "$curr_id" -gt 1 ]]; then
                hyprctl dispatch workspace previous
            fi
            exit 0
        fi
    else
        # Currently on an occupied workspace.
        if [[ "$curr_id" -le 1 ]]; then
            exit 0
        fi
        target_id=$((curr_id - 1))
        hyprctl dispatch workspace "$target_id"
        exit 0
    fi
fi
