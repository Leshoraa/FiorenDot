#!/usr/bin/env bash
# Project Launcher
# Author: Fioren (@Leshoraa)

rofi_theme="$HOME/.config/rofi/config-projects.rasi"
PROJECTS_DIR="$HOME/Projects"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

if [ ! -d "$PROJECTS_DIR" ]; then
    notify-send -u critical "Project Launcher" "Directory $PROJECTS_DIR not found" -a "Projects"
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
    notify-send "Project Launcher" "No projects found in ~/Projects" -a "Projects"
    exit 0
fi

CHOSEN=$(echo "$PROJECT_LIST" | rofi -dmenu \
    -config "$rofi_theme" \
    -i \
    -kb-custom-1 "Alt+Return" \
    -kb-custom-2 "Alt+f" \
    -kb-custom-3 "Alt+b" \
    -mesg "󰌌 <b>Enter</b>: Editor | <b>Alt+Enter</b>: Kitty | <b>Alt+F</b>: Thunar | <b>Alt+B</b>: Both" \
    -p "Projects"
)

ROFI_STATUS=$?

if [ $ROFI_STATUS -ne 0 ] && [ $ROFI_STATUS -ne 10 ] && [ $ROFI_STATUS -ne 11 ] && [ $ROFI_STATUS -ne 12 ]; then
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

OPEN_EDITOR() {
    if command -v antigravity >/dev/null 2>&1; then
        antigravity "$TARGET_DIR" &
    elif command -v codium >/dev/null 2>&1; then
        codium "$TARGET_DIR" &
    else
        notify-send -u critical "Project Launcher" "No GUI editor found" -a "Projects"
    fi
}

OPEN_TERMINAL() {
    kitty --directory "$TARGET_DIR" &
}

OPEN_FILES() {
    thunar "$TARGET_DIR" &
}

case $ROFI_STATUS in
    0)
        OPEN_EDITOR
        notify-send -i "applications-development" "Project Launcher" "Opened $REL_PATH in Editor" -a "Projects"
        ;;
    10)
        OPEN_TERMINAL
        notify-send -i "terminal" "Project Launcher" "Opened terminal in $REL_PATH" -a "Projects"
        ;;
    11)
        OPEN_FILES
        notify-send -i "system-file-manager" "Project Launcher" "Opened $REL_PATH in Thunar" -a "Projects"
        ;;
    12)
        OPEN_EDITOR
        OPEN_TERMINAL
        notify-send -i "applications-development" "Project Launcher" "Opened $REL_PATH in Editor & Terminal" -a "Projects"
        ;;
esac
