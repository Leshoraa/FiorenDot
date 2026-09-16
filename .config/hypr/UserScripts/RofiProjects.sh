#!/usr/bin/env bash
# /* ---- 💫 FiorenDot - ASUS Vivobook S 14 Flip 💫 ---- */
# Author: Fioren (@Leshoraa)
# Description: Quick Project Switcher for Rofi with 0 MB standby RAM footprint.
# Shortcuts in Menu:
#   Enter       -> Buka di GUI Editor (Antigravity / Codium)
#   Alt + Enter -> Buka di Terminal (Kitty)
#   Alt + F     -> Buka di File Manager (Thunar)
#   Alt + B     -> Buka Keduanya (Editor + Terminal)

rofi_theme="$HOME/.config/rofi/config-projects.rasi"
PROJECTS_DIR="$HOME/Projects"

# Tutup rofi jika sudah berjalan
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

if [ ! -d "$PROJECTS_DIR" ]; then
    notify-send -u critical "Project Switcher" "Direktori $PROJECTS_DIR tidak ditemukan!" -a "FiorenDot Projects"
    exit 1
fi

# Pindai project secara cerdas & cepat menggunakan Python (eksekusi < 15ms)
PROJECT_LIST=$(python3 - <<EOF
import os

projects_dir = os.path.expanduser("~/Projects")
projects = set()

for item in sorted(os.listdir(projects_dir)):
    p1 = os.path.join(projects_dir, item)
    if not os.path.isdir(p1) or item.startswith("."):
        continue
    
    # Repository git tingkat 1
    if os.path.exists(os.path.join(p1, ".git")):
        projects.add(item)
        continue
    
    # Subfolder di dalam kategori (misal CLI/..., Web/..., Readme/...)
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
    notify-send "Project Switcher" "Tidak ada proyek yang ditemukan di ~/Projects" -a "FiorenDot Projects"
    exit 0
fi

# Tampilkan Rofi menu
CHOSEN=$(echo "$PROJECT_LIST" | rofi -dmenu \
    -config "$rofi_theme" \
    -i \
    -kb-custom-1 "Alt+Return" \
    -kb-custom-2 "Alt+f" \
    -kb-custom-3 "Alt+b" \
    -mesg "󰌌 <b>Enter</b>: Editor | <b>Alt+Enter</b>: Kitty | <b>Alt+F</b>: Thunar | <b>Alt+B</b>: Keduanya" \
    -p "Projects"
)

ROFI_STATUS=$?

# Batalkan jika user menekan Esc
if [ $ROFI_STATUS -ne 0 ] && [ $ROFI_STATUS -ne 10 ] && [ $ROFI_STATUS -ne 11 ] && [ $ROFI_STATUS -ne 12 ]; then
    exit 0
fi

if [ -z "$CHOSEN" ]; then
    exit 0
fi

# Bersihkan icon dari nama project
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
        notify-send -u critical "Project Switcher" "Editor GUI tidak ditemukan!" -a "FiorenDot Projects"
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
        # Enter -> Default: Editor
        OPEN_EDITOR
        notify-send -i "applications-development" "Project Dibuka" "Membuka $REL_PATH di Editor" -a "FiorenDot Projects"
        ;;
    10)
        # Alt + Enter -> Terminal Kitty
        OPEN_TERMINAL
        notify-send -i "terminal" "Project Terminal" "Membuka terminal di $REL_PATH" -a "FiorenDot Projects"
        ;;
    11)
        # Alt + F -> Thunar File Manager
        OPEN_FILES
        notify-send -i "system-file-manager" "Project Files" "Membuka $REL_PATH di Thunar" -a "FiorenDot Projects"
        ;;
    12)
        # Alt + B -> Keduanya (Editor + Terminal)
        OPEN_EDITOR
        OPEN_TERMINAL
        notify-send -i "applications-development" "Workspace Siap" "Membuka $REL_PATH di Editor & Terminal" -a "FiorenDot Projects"
        ;;
esac
