-- Author: Fioren (@Leshoraa)
-- User Startup Apps (Hyprland 0.57+ Lua)

local home = os.getenv("HOME")
local UserScripts = home .. "/.config/hypr/UserScripts"

hl.on("hyprland.start", function()
    -- Turn off Bluetooth on startup
    hl.exec_cmd("bluetoothctl power off")

    -- Pinch-to-Zoom daemon (2-finger pinch -> cursor:zoom_factor)
    hl.exec_cmd("sleep 0.5 && python3 " .. UserScripts .. "/PinchZoom.py")
end)
