-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Main Hyprland Lua configuration entry point (Hyprland 0.57+)

-- Pre-configured defaults and user overrides
require("configs.Keybinds")
require("configs.Startup_Apps")
require("UserConfigs.Startup_Apps")

require("configs.ENVariables")
require("UserConfigs.ENVariables")

-- Laptop related
require("configs.Laptops")
require("UserConfigs.Laptops")
require("UserConfigs.LaptopDisplay")

-- Window and layer rules
require("configs.WindowRules")
require("UserConfigs.WindowRules")

-- System & user settings
require("configs.SystemSettings")
require("UserConfigs.UserDecorations")
require("UserConfigs.UserAnimations")
require("UserConfigs.UserKeybinds")
require("UserConfigs.UserSettings")
require("UserConfigs.01-UserDefaults")

-- Monitors & workspaces
require("monitors")
require("workspaces")

-- Phantomat (guarded until spatialoverview.so is rebuilt for 0.57+)
require("UserConfigs.Phantomat")
