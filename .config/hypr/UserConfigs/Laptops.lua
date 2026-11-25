-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- User Laptop Overrides (lid switch examples preserved)

-- Example lid switch bindings for external display setups:
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl eval 'hl.monitor({ output = \"eDP-1\", mode = \"preferred\", position = \"auto\", scale = 1 })'"), { locked = true })
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl eval 'hl.monitor({ output = \"eDP-1\", disabled = true })'"), { locked = true })
