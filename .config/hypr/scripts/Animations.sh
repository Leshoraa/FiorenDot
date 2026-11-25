#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified by: Fioren (@Leshoraa)
# For applying Animations from different users

# Check if rofi is already running (wait briefly for layer-shell teardown)
if pgrep -x rofi > /dev/null; then
  pkill -x rofi
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x rofi > /dev/null || break
    sleep 0.03
  done
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
# Author: Fioren (@Leshoraa) | Base: JaKooLit
# For applying Animations from presets into UserAnimations.lua (Hyprland 0.57+ Lua)
msg='󰋼 NOTE: This will convert & apply animations into UserAnimations.lua'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Rofi Menu
chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme)

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.conf"
    python3 - "$full_path" "$UserConfigs/UserAnimations.lua" "$chosen_file" << 'PYEOF'
import re, sys
src, dst, name = sys.argv[1], sys.argv[2], sys.argv[3]
enabled = True
beziers = []
anims = []
with open(src, 'r', encoding='utf-8', errors='replace') as f:
    for raw in f:
        line = raw.split('#', 1)[0].strip()
        if not line or '=' not in line:
            continue
        k, v = [x.strip() for x in line.split('=', 1)]
        if k == 'enabled':
            enabled = v.lower() in ('yes', 'true', '1', 'on')
        elif k == 'bezier':
            parts = [p.strip() for p in v.split(',')]
            if len(parts) >= 5:
                bname, x0, y0, x1, y1 = parts[:5]
                beziers.append((bname, x0, y0, x1, y1))
        elif k == 'animation':
            parts = [p.strip() for p in v.split(',')]
            if len(parts) >= 4:
                leaf = parts[0]
                onoff = parts[1].lower() in ('1', 'yes', 'true', 'on')
                speed = parts[2]
                curve = parts[3]
                style = parts[4] if len(parts) > 4 else None
                anims.append((leaf, onoff, speed, curve, style))

out = [
    f"-- Author: Fioren (@Leshoraa) | Base: JaKooLit",
    f"-- Preset: {name}",
    "",
    "hl.config({",
    "    animations = {",
    f"        enabled = {'true' if enabled else 'false'},",
    "    },",
    "})",
    "",
]
for bname, x0, y0, x1, y1 in beziers:
    out.append(f'hl.curve("{bname}", {{ type = "bezier", points = {{ {{ {x0}, {y0} }}, {{ {x1}, {y1} }} }} }})')
if beziers:
    out.append("")
for leaf, onoff, speed, curve, style in anims:
    s = f', style = "{style}"' if style else ""
    out.append(f'hl.animation({{ leaf = "{leaf}", enabled = {"true" if onoff else "false"}, speed = {speed}, bezier = "{curve}"{s} }})')

with open(dst, 'w', encoding='utf-8') as f:
    f.write("\n".join(out) + "\n")
PYEOF
    hyprctl reload config-only >/dev/null 2>&1 || true
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Hyprland Animation Loaded"
    sleep 1
    "$SCRIPTSDIR/RefreshNoWaybar.sh"
fi
