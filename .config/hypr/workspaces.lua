-- Author: Fioren (@Leshoraa) | Base: JaKooLit
-- Workspace rules: keep primary workspaces 1-5 anchored on laptop eDP-1
-- so plugging an HDMI monitor/projector never steals laptop windows.

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1" })
