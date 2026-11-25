-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- User Settings (migrated from UserSettings.conf)

local home = os.getenv("HOME")
local UserScripts = home .. "/.config/hypr/UserScripts"

hl.config({
    input = {
        touchpad = {
            disable_while_typing = false,
            natural_scroll = false,
            clickfinger_behavior = true,
            middle_button_emulation = true,
            tap_to_click = true,
            drag_lock = 1,
        },

        touchdevice = {
            enabled = false,
            output = "eDP-1",
        },

        tablet = {
            output = "eDP-1",
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 10,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
        workspace_swipe_touch = true,
    },

    render = {
        direct_scanout = 0,
    },

    cursor = {
        inactive_timeout = 3,
        hide_on_key_press = true,
        hide_on_touch = true,
    },
})

-- Explicitly disable both finger touch and stylus digitizer
hl.device({
    name = "wdht1f01:00-2575:0911",
    enabled = false,
})

hl.device({
    name = "wdht1f01:00-2575:0911-stylus",
    enabled = false,
})

-- Touchpad Multi-Finger Gestures (Hyprland 0.57+)
-- 3 Fingers: Workspace Swipe & Desktop Zoom (2x Step Up, Instant Reset Down)
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd(UserScripts .. "/ZoomDesktop.sh in 2.0"))
    end,
})
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd(UserScripts .. "/ZoomDesktop.sh reset"))
    end,
})

-- 4 Fingers: Terminal, Scratchpad & Moving Windows
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd("kitty"))
    end,
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.workspace.toggle_special())
    end,
})
hl.gesture({
    fingers = 4,
    direction = "left",
    action = function()
        hl.dispatch(hl.dsp.window.move({ workspace = "+1" }))
    end,
})
hl.gesture({
    fingers = 4,
    direction = "right",
    action = function()
        hl.dispatch(hl.dsp.window.move({ workspace = "-1" }))
    end,
})
