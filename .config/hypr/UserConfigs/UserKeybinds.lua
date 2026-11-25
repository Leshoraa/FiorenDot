-- Author: Fioren (@Leshoraa)
-- User Keybindings (Hyprland 0.57+ Lua)

local home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

-- Toggle Virtual Keyboard for Tablet Mode
hl.unbind(mainMod .. " + K")
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(UserScripts .. "/VirtualKeyboardToggle.sh"), { description = "Toggle tablet virtual keyboard on/off" })

-- Toggle Do Not Disturb (DND)
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -d -sw"), { description = "Toggle Do Not Disturb" })

-- Screen OCR
hl.unbind(mainMod .. " + SHIFT + O")
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(UserScripts .. "/ScreenOCR.sh"), { description = "Screen OCR to Clipboard" })

-- Quick Project Switcher
hl.unbind(mainMod .. " + SHIFT + P")
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(UserScripts .. "/RofiProjects.sh"), { description = "Quick Project Switcher" })

-- Pin / Sticky Floating Window
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd(UserScripts .. "/PinWindow.sh"), { description = "Pin or unpin floating window" })

-- Toggle CPU Turbo Boost
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(scriptsDir .. "/CpuBoostToggle.sh toggle"), { description = "Toggle CPU Turbo Boost" })
hl.bind(mainMod .. " + SHIFT + b", hl.dsp.exec_cmd(scriptsDir .. "/CpuBoostToggle.sh toggle"), { description = "Toggle CPU Turbo Boost" })

-- On-Screen Annotation / Drawing (Wayscriber)
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(UserScripts .. "/WayscriberToggle.sh toggle"), { description = "Toggle screen drawing" })

-- Smart Toggle Floating
hl.unbind(mainMod .. " + SPACE")
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(UserScripts .. "/ToggleFloat.sh"), { description = "Smart toggle floating" })

-- Smart Toggle Maximize
hl.unbind(mainMod .. " + ALT + F")
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd(UserScripts .. "/ToggleMaximize.sh"), { description = "Smart toggle maximize" })

-- Display / Projector Mode Switcher (Extend / Mirror / Laptop / External)
hl.bind("XF86Display", hl.dsp.exec_cmd(scriptsDir .. "/DisplayManager.sh menu"), { description = "Display mode menu (Extend/Mirror)" })
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(scriptsDir .. "/DisplayManager.sh menu"), { description = "Display mode menu (Extend/Mirror)" })
