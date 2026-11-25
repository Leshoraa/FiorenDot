#!/usr/bin/env bash
# Author: Fioren (@Leshoraa)
# Smart Display & HDMI/Projector Manager for Hyprland 0.57+
# Guarantees eDP-1 (laptop) never blanks/shifts unintentionally and selects
# flicker-free 8-bit 50-60Hz modes for external monitors & projectors.
#
# Usage: DisplayManager.sh [auto|extend|mirror|laptop|external|ensure-laptop|menu]

set -euo pipefail

ACTION="${1:-auto}"
LAPTOP="eDP-1"
PREF_FILE="/tmp/display_mode_pref"
LOCK_FILE="/tmp/display_manager.lock"
ROFI_THEME="$HOME/.config/rofi/config-Monitors.rasi"
ICON_DIR="$HOME/.config/swaync/images"

notify_disp() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -u low -i "$ICON_DIR/ja.png" "Display" "$1" 2>/dev/null || true
}

close_overview_if_active() {
  if [[ -e /tmp/phantom_active ]]; then
    hyprctl eval 'pcall(hl.plugin.spatialoverview.overview, "off")' >/dev/null 2>&1 || true
    sleep 0.08
  fi
}

show_menu() {
  if pidof rofi >/dev/null 2>&1; then
    pkill -x rofi || true
  fi
  local opts="󰍺  Extend (Auto Safe)\n󰍹  Mirror (Projector)\n󰌢  Laptop Only\n󰶐  External Only"
  local choice
  choice=$(printf "%b\n" "$opts" | rofi -i -dmenu -p "Display Mode" -config "$ROFI_THEME" || true)
  case "$choice" in
    *Extend*)   exec "$0" extend ;;
    *Mirror*)   exec "$0" mirror ;;
    *Laptop*)   exec "$0" laptop ;;
    *External*) exec "$0" external ;;
    *)          exit 0 ;;
  esac
}

if [[ "$ACTION" == "menu" ]]; then
  show_menu
fi

exec 202>"$LOCK_FILE"
flock -x -w 4 202 || exit 0

if [[ "$ACTION" == "auto" ]]; then
  pref="extend"
  if [[ -f "$PREF_FILE" ]]; then
    IFS= read -r raw_pref < "$PREF_FILE" 2>/dev/null || true
    if [[ "$raw_pref" == "mirror" || "$raw_pref" == "extend" ]]; then
      pref="$raw_pref"
    fi
  fi
  EFFECTIVE_ACTION="$pref"
  IS_AUTO=1
else
  EFFECTIVE_ACTION="$ACTION"
  IS_AUTO=0
fi

# Close Phantomat overview cleanly if open before monitor layout changes
if [[ "$EFFECTIVE_ACTION" != "ensure-laptop" ]]; then
  close_overview_if_active
fi

RESULT=$(python3 - "$EFFECTIVE_ACTION" "$LAPTOP" "$IS_AUTO" "$PREF_FILE" << 'PYEOF'
import json
import re
import subprocess
import sys

action, laptop, is_auto_str, pref_file = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
is_auto = (is_auto_str == "1")

raw = subprocess.check_output(["hyprctl", "monitors", "all", "-j"], text=True)
monitors = json.loads(raw)

laptop_mon = next((m for m in monitors if m.get("name") == laptop), None)
externals = [m for m in monitors if m.get("name") and m.get("name") != laptop]

def pick_safe_mode(avail_modes, is_mirror=False):
    parsed = []
    for s in (avail_modes or []):
        m = re.match(r"^(\d+)x(\d+)@([\d.]+)Hz$", s.strip())
        if not m:
            continue
        w, h, hz = int(m.group(1)), int(m.group(2)), float(m.group(3))
        if w < 640 or h < 480:
            continue
        parsed.append((w, h, hz))
    if not parsed:
        return "preferred", 1

    # Prefer standard stable 50-62Hz modes to avoid 30Hz lag or 120Hz+ HDMI cable flicker
    stable = [p for p in parsed if 50.0 <= p[2] <= 62.0]
    pool = stable if stable else parsed

    if is_mirror:
        # Cap mirror mode at <=2560x1600 so 4K TVs don't waste HDMI bandwidth while mirroring 1920x1200
        mirror_pool = [p for p in pool if p[0] <= 2560 and p[1] <= 1600]
        if mirror_pool:
            pool = mirror_pool

    best = max(pool, key=lambda p: (p[0] * p[1], -abs(p[2] - 60.0)))
    w, h, hz = best
    scale = 1
    if not is_mirror and w >= 3200:
        scale = 1.5
    return f"{w}x{h}@{hz:.2f}", scale

def laptop_rule():
    return (
        f'hl.monitor({{ output = "{laptop}", mode = "1920x1200@60.0", '
        f'position = "0x0", scale = 1.2, bitdepth = 8, vrr = 0 }})'
    )

cmds = []
msg = ""

if action == "ensure-laptop":
    if not externals and laptop_mon and laptop_mon.get("disabled", False):
        cmds.append(laptop_rule())
        cmds.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{laptop}" }}))')
        msg = "External disconnected: restored laptop display"
elif action == "laptop":
    cmds.append(laptop_rule())
    for ext in externals:
        cmds.append(f'hl.monitor({{ output = "{ext["name"]}", disabled = true }})')
    cmds.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{laptop}" }}))')
    msg = "Laptop Only (eDP-1)"
elif action == "external":
    if not externals:
        print("NO_EXT|No external display detected")
        sys.exit(0)
    for idx, ext in enumerate(externals):
        mode, scale = pick_safe_mode(ext.get("availableModes"), is_mirror=False)
        pos = "0x0" if idx == 0 else "auto-right"
        cmds.append(
            f'hl.monitor({{ output = "{ext["name"]}", mode = "{mode}", '
            f'position = "{pos}", scale = {scale}, bitdepth = 8, vrr = 0 }})'
        )
    cmds.append(f'hl.monitor({{ output = "{laptop}", disabled = true }})')
    cmds.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{externals[0]["name"]}" }}))')
    msg = f"External Only ({externals[0]['name']})"
elif action == "mirror":
    if not externals:
        if is_auto:
            sys.exit(0)
        print("NO_EXT|No external display detected")
        sys.exit(0)
    with open(pref_file, "w") as f:
        f.write("mirror\n")
    cmds.append(laptop_rule())
    ext_desc = []
    for ext in externals:
        mode, _ = pick_safe_mode(ext.get("availableModes"), is_mirror=True)
        cmds.append(
            f'hl.monitor({{ output = "{ext["name"]}", mode = "{mode}", '
            f'position = "auto", scale = 1, bitdepth = 8, vrr = 0, mirror = "{laptop}" }})'
        )
        ext_desc.append(f"{ext['name']} ({mode})")
    cmds.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{laptop}" }}))')
    msg = "Mirror: " + ", ".join(ext_desc)
elif action == "extend":
    if not externals:
        if is_auto:
            if laptop_mon and laptop_mon.get("disabled", False):
                cmds.append(laptop_rule())
            else:
                sys.exit(0)
        else:
            print("NO_EXT|No external display detected")
            sys.exit(0)
    else:
        with open(pref_file, "w") as f:
            f.write("extend\n")
        cmds.append(laptop_rule())
        ext_desc = []
        for ext in externals:
            mode, scale = pick_safe_mode(ext.get("availableModes"), is_mirror=False)
            cmds.append(
                f'hl.monitor({{ output = "{ext["name"]}", mode = "{mode}", '
                f'position = "auto-right", scale = {scale}, bitdepth = 8, vrr = 0 }})'
            )
            ext_desc.append(f"{ext['name']} ({mode})")
        cmds.append(f'hl.dispatch(hl.dsp.focus({{ monitor = "{laptop}" }}))')
        msg = "Extend: " + ", ".join(ext_desc)

if cmds:
    lua_code = "; ".join(cmds)
    subprocess.run(["hyprctl", "eval", lua_code], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if msg:
        print(f"OK|{msg}")
PYEOF
)

if [[ -n "$RESULT" ]]; then
  status="${RESULT%%|*}"
  text="${RESULT#*|}"
  notify_disp "$text"
fi
