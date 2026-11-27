#!/usr/bin/env bash
# Sync active Wallust wallpaper palette into /etc/greetd/tuigreet-palette

set -euo pipefail

SRC="${XDG_CONFIG_HOME:-$HOME/.config}/wallust/tuigreet-palette"
DST="/etc/greetd/tuigreet-palette"

[ -f "$SRC" ] || exit 0
[ -w "$DST" ] || exit 0

CLEAN="$(grep -E '^P[0-9A-F]="[0-9A-Fa-f]{6}"$' "$SRC" || true)"
if [ -n "$CLEAN" ]; then
    printf '%s\n' "$CLEAN" > "$DST"
fi
