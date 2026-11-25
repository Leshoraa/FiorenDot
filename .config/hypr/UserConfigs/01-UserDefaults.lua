-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- User defaults for apps, editor, and search engine

local M = {}

hl.env("EDITOR", "vim")

M.editor = os.getenv("EDITOR") or "vim"
M.term = "kitty"
M.files = "thunar"
M.search_engine = "https://www.google.com/search?q={}"

return M
