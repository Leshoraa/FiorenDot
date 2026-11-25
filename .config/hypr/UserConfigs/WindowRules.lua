-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- User Window & Layer Rules (overlay)

-- Rofi layer rules
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })

-- Virtual keyboard (wvkbd) layer rules
hl.layer_rule({ match = { namespace = "wvkbd" }, blur = true })

-- SwayNC layer rules
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.5 })

-- Quickshell Mini Alarm layer rules
hl.layer_rule({ match = { namespace = "quickshell:alarm" }, blur = true, ignore_alpha = 0.5 })

-- Scrcpy window rules
hl.window_rule({ match = { class = "^([Ss]crcpy)$" }, float = true, center = true })
