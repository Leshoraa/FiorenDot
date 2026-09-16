#!/usr/bin/env bash
# FiorenDot - Project Launcher
# Author: Fioren (@Leshoraa)

rofi_theme="$HOME/.config/rofi/config-projects.rasi"
PROJECTS_DIR="$HOME/Projects"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

if [ ! -d "$PROJECTS_DIR" ]; then
    notify-send -u critical "Projects" "Directory $PROJECTS_DIR not found" -a "Projects"
    exit 1
fi

PROJECT_LIST=$(python3 - <<EOF
import os

projects_dir = os.path.expanduser("~/Projects")
projects = set()

for item in sorted(os.listdir(projects_dir)):
    p1 = os.path.join(projects_dir, item)
    if not os.path.isdir(p1) or item.startswith("."):
        continue
    
    if os.path.exists(os.path.join(p1, ".git")):
        projects.add(item)
        continue
    
    subdirs = [d for d in os.listdir(p1) if os.path.isdir(os.path.join(p1, d)) and not d.startswith(".") and d not in ("node_modules", "dist", "build", ".git", "assets", "__pycache__")]
    if not subdirs:
        projects.add(item)
    else:
        has_root_files = any(f.endswith((".py", ".sh", ".md", ".json", ".js", ".ts", ".toml", ".yaml", ".yml", ".c", ".cpp")) for f in os.listdir(p1) if os.path.isfile(os.path.join(p1, f)))
        for s in subdirs:
            projects.add(f"{item}/{s}")
        if has_root_files and not any(os.path.exists(os.path.join(p1, s, ".git")) for s in subdirs):
            projects.add(item)

for p in sorted(projects):
    print(f"󰘐  {p}")
EOF
)

if [ -z "$PROJECT_LIST" ]; then
    exit 0
fi

CHOSEN=$(echo "$PROJECT_LIST" | rofi -dmenu \
    -config "$rofi_theme" \
    -i \
    -kb-custom-1 "Alt+Return" \
    -p "Projects"
)

ROFI_STATUS=$?

if [ $ROFI_STATUS -ne 0 ] && [ $ROFI_STATUS -ne 10 ]; then
    exit 0
fi

if [ -z "$CHOSEN" ]; then
    exit 0
fi

REL_PATH=$(echo "$CHOSEN" | sed -e 's/^󰘐[[:space:]]*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
TARGET_DIR="$PROJECTS_DIR/$REL_PATH"

if [ ! -d "$TARGET_DIR" ]; then
    exit 1
fi

case $ROFI_STATUS in
    0)
        kitty --directory "$TARGET_DIR" &
        ;;
    10)
        if command -v antigravity >/dev/null 2>&1; then
            antigravity "$TARGET_DIR" &
        elif command -v codium >/dev/null 2>&1; then
            codium "$TARGET_DIR" &
        fi
        ;;
esac
