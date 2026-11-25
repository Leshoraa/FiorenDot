#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified by: Fioren (@Leshoraa)
# For applying Pre-configured Monitor Profiles

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
# Author: Fioren (@Leshoraa) | Base: JaKooLit
monitor_dir="$HOME/.config/hypr/Monitor_Profiles"
target="$HOME/.config/hypr/monitors.lua"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg='󰋼 NOTE: This will overwrite $HOME/.config/hypr/monitors.lua'

# Define the list of files to ignore
ignore_files=(
  "README"
)

# list of Monitor Profiles, sorted alphabetically with numbers first
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Remove ignored files from the list
for ignored_file in "${ignore_files[@]}"; do
    mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

# Prepend instant DisplayManager modes (Extend / Mirror / Laptop Only / External Only)
quick_modes=$'Extend (Auto Safe)\nMirror (Projector)\nLaptop Only\nExternal Only'
menu_entries="$quick_modes"
if [[ -n "$mon_profiles_list" ]]; then
    menu_entries+=$'\n'"$mon_profiles_list"
fi

# Rofi Menu
chosen_file=$(echo "$menu_entries" | rofi -i -dmenu -config $rofi_theme || true)

case "$chosen_file" in
    "Extend (Auto Safe)") exec "$SCRIPTSDIR/DisplayManager.sh" extend ;;
    "Mirror (Projector)")  exec "$SCRIPTSDIR/DisplayManager.sh" mirror ;;
    "Laptop Only")        exec "$SCRIPTSDIR/DisplayManager.sh" laptop ;;
    "External Only")      exec "$SCRIPTSDIR/DisplayManager.sh" external ;;
esac

if [[ -n "$chosen_file" ]]; then
    full_path="$monitor_dir/$chosen_file.conf"
    python3 - "$full_path" "$target" "$chosen_file" << 'PYEOF'
import sys
src, dst, name = sys.argv[1], sys.argv[2], sys.argv[3]
lines = [
    f"-- Author: Fioren (@Leshoraa) | Base: JaKooLit",
    f"-- Monitor Profile: {name}",
    "",
]
with open(src, 'r', encoding='utf-8', errors='replace') as f:
    for raw in f:
        s = raw.split('#', 1)[0].strip()
        if not s.startswith('monitor'):
            continue
        if '=' not in s:
            continue
        _, val = s.split('=', 1)
        parts = [p.strip() for p in val.split(',')]
        if not parts:
            continue
        out = parts[0] if parts[0] else ""
        if len(parts) >= 2 and parts[1] == "disable":
            lines.append(f'hl.monitor({{ output = "{out}", disabled = true }})')
            continue
        mode = parts[1] if len(parts) > 1 and parts[1] else "preferred"
        pos = parts[2] if len(parts) > 2 and parts[2] else "auto"
        scale = parts[3] if len(parts) > 3 and parts[3] else "1"
        extras = []
        i = 4
        while i < len(parts):
            k = parts[i]
            if k in ("bitdepth", "transform", "mirror") and i + 1 < len(parts):
                v = parts[i + 1]
                if k in ("bitdepth", "transform"):
                    extras.append(f"{k} = {v}")
                else:
                    extras.append(f'{k} = "{v}"')
                i += 2
            else:
                i += 1
        extra_str = (", " + ", ".join(extras)) if extras else ""
        lines.append(f'hl.monitor({{ output = "{out}", mode = "{mode}", position = "{pos}", scale = {scale}{extra_str} }})')

with open(dst, 'w', encoding='utf-8') as f:
    f.write("\n".join(lines) + "\n")
PYEOF
    hyprctl reload config-only >/dev/null 2>&1 || true
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/RefreshNoWaybar.sh &