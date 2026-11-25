-- Author: Fioren (@Leshoraa)
-- Phantomat - Spatial Overview & Zoomable Window Manager (Hyprland 0.57+ Lua)
local plugin_path = os.getenv("HOME") .. "/.local/share/spatial-overview/spatialoverview.so"
pcall(hl.plugin.load, plugin_path)

local loaded = false
for _, plugin in ipairs(hl.get_loaded_plugins()) do
    if plugin.name == "spatialoverview" then
        loaded = true
        break
    end
end

if not loaded then
    hl.on("hyprland.start", function()
        hl.exec_cmd("[ -f '" .. plugin_path .. "' ] && ! hyprctl plugin list | grep -q spatialoverview && hyprctl plugin load '" .. plugin_path .. "' && hyprctl reload")
    end)

    -- Fallback Alt+Tab MRU window switcher (works across workspaces too) while Phantomat is not loaded
    hl.bind("ALT + Tab", function()
        local active = hl.get_active_window()
        local active_addr = active and active.address or nil
        local best, best_id = nil, math.huge
        for _, w in ipairs(hl.get_windows()) do
            if w.mapped and w.address ~= active_addr then
                local h = w.focus_history_id or math.huge
                if h > 0 and h < best_id then
                    best = w
                    best_id = h
                end
            end
        end
        if best then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. best.address }))
            hl.dispatch(hl.dsp.window.bring_to_top())
        else
            hl.dispatch(hl.dsp.window.cycle_next())
            hl.dispatch(hl.dsp.window.bring_to_top())
        end
    end, { repeating = true, description = "Switch to recent window" })

    hl.bind("ALT + SHIFT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end, { repeating = true, description = "Cycle previous window" })
    return
end

hl.config({
    plugin = {
        spatialoverview = {
            layout = "grid",
            scale = 0.36,

            animation = {
                enabled = true,
                speed = 6.0,
                bezier = "wind",
            },

            input = {
                pan_sensitivity = 1.0,
                drag_mode = 1,
                touchpad_scroll_factor = 1.0,
                drag_threshold = 10,
            },

            canvas = {
                enabled = true,
                desktop_mode = false,
                persistent = false,
                auto_float = false,
                auto_place = false,
                initial_zoom = 0.72,
                min_zoom = 0.001,
                max_zoom = 50.0,
                zoom_step = 0.12,
                direct_input = true,
                hover_focus = true,
                minimap_enabled = true,
                grid_enabled = false,
                grid_style = 1,
                remember_layout = false,
                viewport_enabled = false,
            },

            workspace_outline = {
                enabled = false,
            },

            distortion = {
                enabled = false,
                strength = 0.0,
            },
        },
    },
})

local mainMod = "SUPER"

local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.unbind("ALT + tab")
hl.bind("ALT + tab", function()
    pcall(hl.plugin.spatialoverview.overview, "toggle all")
end, { description = "Toggle Spatial Overview" })

hl.unbind(mainMod .. " + ALT + SPACE")
hl.unbind(mainMod .. " + ALT + space")
hl.bind(mainMod .. " + ALT + space", function()
    pcall(hl.plugin.spatialoverview.overview, "toggle all")
end, { description = "Toggle Spatial Overview" })

hl.unbind(mainMod .. " + ALT + left")
hl.unbind(mainMod .. " + ALT + right")
hl.unbind(mainMod .. " + ALT + up")
hl.unbind(mainMod .. " + ALT + down")
hl.bind(mainMod .. " + ALT + left",  function() pcall(hl.plugin.spatialoverview.navigate, "left") end,  { description = "Navigate Left" })
hl.bind(mainMod .. " + ALT + right", function() pcall(hl.plugin.spatialoverview.navigate, "right") end, { description = "Navigate Right" })
hl.bind(mainMod .. " + ALT + up",    function() pcall(hl.plugin.spatialoverview.navigate, "up") end,    { description = "Navigate Up" })
hl.bind(mainMod .. " + ALT + down",  function() pcall(hl.plugin.spatialoverview.navigate, "down") end,  { description = "Navigate Down" })

hl.bind(mainMod .. " + equal", function() pcall(hl.plugin.spatialoverview.canvas, "zoom in") end,  { description = "Zoom In Overview" })
hl.bind(mainMod .. " + plus",  function() pcall(hl.plugin.spatialoverview.canvas, "zoom in") end,  { description = "Zoom In Overview" })
hl.bind(mainMod .. " + minus", function() pcall(hl.plugin.spatialoverview.canvas, "zoom out") end, { description = "Zoom Out Overview" })
hl.bind(mainMod .. " + 0",     function() pcall(hl.plugin.spatialoverview.canvas, "fit") end,      { description = "Fit All on Overview" })

hl.unbind(mainMod .. " + SHIFT + A")
hl.bind(mainMod .. " + SHIFT + A", function()
    if not pcall(hl.plugin.spatialoverview.canvas, "arrange") then
        hl.dispatch(hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"))
    end
end, { description = "Arrange canvas or open animations menu" })
