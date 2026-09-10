#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

BACKEND=wayland

if pidof rofi > /dev/null; then pkill rofi; fi
if pidof yad > /dev/null; then pkill yad; fi

GDK_BACKEND=$BACKEND yad \
    --center \
    --title="KooL Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Command: \
    --timeout-indicator=bottom \
"ESC" "close this app" "" \
" = " "SUPER KEY" "(Windows Key)" \
" H" "Launch this Cheat Sheet" "KeyHints" \
" SHIFT K" "Searchable Keybinds" "Rofi Binds" \
" SHIFT E" "Quick Settings Menu" "Kool Settings" \
" SHIFT A" "Animations Menu" "Rofi Animations" \
"" "" "" \
" Enter" "Terminal" "($term)" \
" SHIFT Enter" "DropDown Terminal" "Scratchpad" \
" T" "File Manager" "($files)" \
" B" "Default Browser" "xdg-open" \
" C" "VS Code" "Code Editor" \
" D" "Application Launcher" "Rofi Drun" \
" S" "Web Search" "Rofi Search" \
" CTRL S" "Window Switcher" "Rofi Window" \
" ALT V" "Clipboard Manager" "ClipManager" \
" ALT C" "Calculator" "Rofi Calc" \
" SHIFT M" "Online Music" "Rofi Beats" \
"" "" "" \
" Q" "Close active window" "KillActive" \
" SHIFT Q" "Force Kill Process" "Kill Process" \
" L" "Suspend System" "systemctl suspend" \
"CTRL ALT L" "Lock Screen" "Hyprlock" \
"CTRL ALT P" "Power Menu" "Wlogout" \
"CTRL ALT Del" "Exit Hyprland" "Hyprctl Exit" \
"" "" "" \
" W" "Select Wallpaper" "WallpaperSelect" \
" SHIFT W" "Wallpaper Effects" "WallEffects" \
"CTRL ALT W" "Random Wallpaper" "Swww" \
" CTRL ALT B" "Hide/UnHide Waybar" "Waybar Toggle" \
" CTRL B" "Waybar Styles" "Waybar Menu" \
" ALT B" "Waybar Layout" "Layout Menu" \
" ALT R" "Refresh Bar & Menus" "Refresh Script" \
" ALT N" "Notification Panel" "SwayNC" \
" SHIFT O" "Change Oh-My-Zsh Theme" "Zsh Themes" \
"" "" "" \
"Print" "Screenshot Now" "Grim" \
" SHIFT Print" "Screenshot Area" "Grim+Slurp" \
" SHIFT S" "Screenshot (Swappy)" "Editor Mode" \
"ALT Print" "Screenshot Active" "Window only" \
"" "" "" \
" SHIFT F" "Fullscreen" "Full" \
" ALT F" "Maximize Window" "Max" \
" SPACE" "Float Center & Resize" "Floating" \
" ALT SPACE" "Float All Windows" "All Workspace" \
" SHIFT G" "Gamemode" "Toggle Anim" \
" ALT O" "Toggle Blur" "Blur ON/OFF" \
" CTRL O" "Toggle Active Opacity" "Opaque Toggle" \
" U" "Toggle Special Workspace" "Scratchpad" \
" SHIFT U" "Move to Special Workspace" "Move to Scratch" \
" SHIFT T" "Toggle Touchscreen" "Enable/Disable" \
"" "" "" \
"More tips:" "https://github.com/JaKooLit/Hyprland-Dots/wiki" ""