-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Decoration Settings (dynamically reads wallust-hyprland.conf colors)

local function load_wallust_colors()
    local colors = {
        primary = "rgb(9197CA)",
        color0  = "rgb(202027)",
        color1  = "rgb(C77C75)",
        color2  = "rgb(75C783)",
        color8  = "rgb(404056)",
        color11 = "rgb(D9CFA1)",
        color13 = "rgb(9CCBD3)",
    }
    local path = os.getenv("HOME") .. "/.config/hypr/wallust/wallust-hyprland.conf"
    local f = io.open(path, "r")
    if not f then
        return colors
    end
    for line in f:lines() do
        local name, val = line:match("^%s*%$([%w_]+)%s*=%s*(rgb%b())")
        if name and val then
            colors[name] = val
        end
    end
    f:close()
    return colors
end

local c = load_wallust_colors()

hl.config({
    general = {
        border_size = 2,
        gaps_in = 1,
        gaps_out = 2,
        col = {
            active_border = c.primary,
            inactive_border = c.color8,
        },
    },

    decoration = {
        rounding = 6,
        active_opacity = 0.95,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.1,
        dim_special = 0.8,

        shadow = {
            enabled = false,
            range = 4,
            render_power = 1,
            color = c.color1,
            color_inactive = c.color11,
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            special = true,
            popups = true,
        },
    },

    group = {
        col = {
            border_active = c.color13,
        },
        groupbar = {
            col = {
                active = c.color0,
            },
        },
    },
})
