-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Commands and Apps to be executed at launch (vendor defaults)

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

hl.on("hyprland.start", function()
    -- Wallpaper daemon
    hl.exec_cmd("awww-daemon")

    -- Environment & keybind init
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(scriptsDir .. "/KeybindsLayoutInit.sh")

    -- Polkit
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- Startup apps
    hl.exec_cmd("swaync")
    hl.exec_cmd("sleep 2 && python " .. UserScripts .. "/infinite_desktop_core.py auto auto 1.0")
    hl.exec_cmd("waybar")

    -- Clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch " .. scriptsDir .. "/ClipStoreImage.sh")

    -- Hypridle for hyprlock
    hl.exec_cmd("systemctl --user start hypridle.service || hypridle")

    hl.exec_cmd("sleep 1 && hyprctl dismissnotify -1")
    hl.exec_cmd('sleep 2 && rot8 --display eDP-1 --hooks "' .. UserScripts .. '/TouchRotate.sh"')
end)
