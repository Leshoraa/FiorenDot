-- Author: Fioren (@Leshoraa)
-- Monitor configuration: keep eDP-1 anchored as primary and safely handle HDMI/DP hotplug

local home = os.getenv("HOME")
local display_script = home .. "/.config/hypr/scripts/DisplayManager.sh"

-- Primary laptop panel (always 8-bit 60Hz at 0x0 so external monitors never displace it)
hl.monitor({
    output = "eDP-1",
    mode = "1920x1200@60.0",
    position = "0x0",
    scale = 1.2,
    bitdepth = 8,
    vrr = 0,
})

-- Safe generic rule for any hot-plugged monitor or projector (8-bit, no VRR, auto-right)
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto-right",
    scale = 1,
    bitdepth = 8,
    vrr = 0,
})

-- Debounced hotplug handler so HDMI EDID & modes settle before applying safe mode
local hotplug_timer = nil

local function schedule_display_sync(action)
    if hotplug_timer then
        hotplug_timer:set_enabled(false)
    end
    hotplug_timer = hl.timer(function()
        hl.exec_cmd(display_script .. " " .. action)
    end, { timeout = 450, type = "oneshot" })
end

hl.on("monitor.added", function(mon)
    local name = mon and mon.name or ""
    if name ~= "eDP-1" then
        schedule_display_sync("auto")
    end
end)

hl.on("monitor.removed", function(mon)
    local name = mon and mon.name or ""
    if name ~= "eDP-1" then
        schedule_display_sync("ensure-laptop")
    end
end)

hl.on("hyprland.start", function()
    if #hl.get_monitors() > 1 then
        schedule_display_sync("auto")
    end
end)
