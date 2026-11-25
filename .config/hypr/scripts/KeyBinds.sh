#!/usr/bin/env bash
# Author: Fioren (@Leshoraa) | Base: JaKooLit
# Searchable enabled keybinds using rofi (queries live Hyprland binds -j for Lua support)

pkill yad || true

if pidof rofi > /dev/null; then
  pkill rofi
fi

rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"

display_keybinds=$(hyprctl binds -j | python3 -c '
import json, sys

binds = json.load(sys.stdin)
MODS = [
    (64, "SUPER"),
    (4,  "CTRL"),
    (8,  "ALT"),
    (1,  "SHIFT"),
]

seen = set()
lines = []
for b in binds:
    mask = b.get("modmask", 0)
    mods = [name for bit, name in MODS if mask & bit]
    key = b.get("key") or (f"code:{b[\"keycode\"]}" if b.get("keycode") else "")
    combo = "+".join(mods + ([key] if key else []))
    if not combo:
        continue
    desc = (b.get("description") or "").strip()
    if b.get("has_description") and desc:
        label = desc
    else:
        disp = (b.get("dispatcher") or "").strip()
        arg = (b.get("arg") or "").strip()
        label = f"{disp} {arg}".strip() if disp else ""
    entry = f"{combo} — {label}" if label else combo
    if entry not in seen:
        seen.add(entry)
        lines.append(entry)

print("\n".join(lines))
')

if [[ -z "$display_keybinds" ]]; then
    echo "no keybinds found."
    exit 1
fi

printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme"
