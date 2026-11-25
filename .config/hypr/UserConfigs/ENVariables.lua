-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- User Environment Variable Overrides

local home = os.getenv("HOME")
local current_path = os.getenv("PATH") or ""

hl.env("PATH", home .. "/.local/bin:" .. current_path)
hl.env("NO_AT_BRIDGE", "1")
hl.env("GSK_RENDERER", "ngl")
