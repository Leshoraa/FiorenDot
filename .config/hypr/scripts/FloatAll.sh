#!/usr/bin/env bash

WORKSPACE_ID=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')

if [ -z "$WORKSPACE_ID" ] || [ "$WORKSPACE_ID" = "null" ]; then
    exit 1
fi

WINDOWS_DATA=$(hyprctl clients -j | jq -c ".[] | select(.workspace.id == $WORKSPACE_ID)")

if [ -z "$WINDOWS_DATA" ]; then
    exit 0
fi

FIRST_WINDOW_STATUS=$(echo "$WINDOWS_DATA" | head -n 1 | jq -r '.floating')

WINDOW_ADDRESSES=$(echo "$WINDOWS_DATA" | jq -r '.address')

for addr in $WINDOW_ADDRESSES; do
    CURRENT_STATUS=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$addr\") | .floating")
    
    if [ "$FIRST_WINDOW_STATUS" = "true" ]; then
        if [ "$CURRENT_STATUS" = "true" ]; then
            hyprctl dispatch togglefloating address:$addr
        fi
    else
        if [ "$CURRENT_STATUS" = "false" ]; then
            hyprctl dispatch togglefloating address:$addr
        fi
    fi
done