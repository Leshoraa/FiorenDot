#!/usr/bin/env bash

# Workspace navigation script (A-Z, IDs 1-26)
# Rules:
# - Can visit 1 empty workspace ahead/behind an occupied workspace.
# - If active workspace is empty:
#   - If there is an occupied workspace ahead (for next) or behind (for prev), jump to it!
#   - If there are NO more occupied workspaces in that direction, wrap around (cycle) to the first/last occupied workspace!
# - Workspaces beyond 26 (outside alphabet) are ignored and will never be jumped to.
# - If currently on an ID > 26 (e.g. 30), next/prev safely returns to the active alphabet workspaces.

direction="${1:-next}"

active_ws=$(hyprctl activeworkspace -j 2>/dev/null)
curr_id=$(jq -r '.id // empty' <<< "$active_ws")

# Ignore special workspaces (e.g. scratchpad with negative IDs)
if [[ -z "$curr_id" || "$curr_id" -lt 1 ]]; then
    exit 0
fi

clients_json=$(hyprctl clients -j 2>/dev/null)

# Count real windows on current workspace excluding pinned windows
curr_windows=$(jq -r --argjson id "$curr_id" '[.[] | select(.workspace.id == $id and (.pinned // false) != true)] | length' <<< "$clients_json" 2>/dev/null || echo 0)

# Occupied workspaces strictly within the A-Z alphabet range (1 to 26), excluding pinned windows
occupied_list=($(jq -r '[.[] | select(.workspace.id >= 1 and .workspace.id <= 26 and (.pinned // false) != true) | .workspace.id] | sort | unique | .[]' <<< "$clients_json" 2>/dev/null))

# If no occupied workspaces exist in 1..26 (e.g. fresh boot), cycle across persistent 1..5
if [[ ${#occupied_list[@]} -eq 0 ]]; then
    if [[ "$direction" == "next" ]]; then
        target_id=$((curr_id + 1))
        if [[ "$target_id" -gt 5 ]]; then
            target_id=1
        fi
        hyprctl dispatch workspace "$target_id"
        exit 0
    elif [[ "$direction" == "prev" ]]; then
        target_id=$((curr_id - 1))
        if [[ "$target_id" -lt 1 ]]; then
            target_id=5
        fi
        hyprctl dispatch workspace "$target_id"
        exit 0
    fi
fi

first_occupied="${occupied_list[0]}"
last_occupied="${occupied_list[-1]}"

if [[ "$direction" == "next" ]]; then
    # If currently beyond Z (e.g. workspace 30), recover to first occupied workspace
    if [[ "$curr_id" -gt 26 ]]; then
        hyprctl dispatch workspace "$first_occupied"
        exit 0
    fi

    if [[ "$curr_windows" -eq 0 ]]; then
        # Currently on an empty workspace.
        # Find the next occupied workspace strictly <= 26
        next_occupied=""
        for ws in "${occupied_list[@]}"; do
            if [[ "$ws" -gt "$curr_id" && "$ws" -le 26 ]]; then
                next_occupied="$ws"
                break
            fi
        done

        if [[ -n "$next_occupied" ]]; then
            # Jump directly to the next occupied workspace (e.g. from D to J)
            hyprctl dispatch workspace "$next_occupied"
            exit 0
        else
            # No more occupied workspaces ahead -> wrap around to the first occupied workspace (e.g. B or A)
            hyprctl dispatch workspace "$first_occupied"
            exit 0
        fi
    else
        # Currently on an occupied workspace.
        target_id=$((curr_id + 1))
        if [[ "$target_id" -gt 26 ]]; then
            hyprctl dispatch workspace "$first_occupied"
            exit 0
        fi
        hyprctl dispatch workspace "$target_id"
        exit 0
    fi

elif [[ "$direction" == "prev" ]]; then
    # If currently beyond Z (e.g. workspace 30), recover to last occupied workspace
    if [[ "$curr_id" -gt 26 ]]; then
        hyprctl dispatch workspace "$last_occupied"
        exit 0
    fi

    if [[ "$curr_windows" -eq 0 ]]; then
        # Currently on an empty workspace.
        # Find the previous occupied workspace strictly >= 1 and < curr_id
        prev_occupied=""
        for (( idx=${#occupied_list[@]}-1; idx>=0; idx-- )); do
            ws="${occupied_list[idx]}"
            if [[ "$ws" -lt "$curr_id" && "$ws" -ge 1 ]]; then
                prev_occupied="$ws"
                break
            fi
        done

        if [[ -n "$prev_occupied" ]]; then
            # Jump directly to previous occupied workspace (e.g. from D to C, or I to C)
            hyprctl dispatch workspace "$prev_occupied"
            exit 0
        else
            # No occupied workspace behind -> wrap around to the last occupied workspace
            hyprctl dispatch workspace "$last_occupied"
            exit 0
        fi
    else
        # Currently on an occupied workspace.
        target_id=$((curr_id - 1))
        if [[ "$target_id" -lt 1 ]]; then
            hyprctl dispatch workspace "$last_occupied"
            exit 0
        fi
        hyprctl dispatch workspace "$target_id"
        exit 0
    fi
fi
