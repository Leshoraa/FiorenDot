-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Laptop specific keybinds and touchpad device settings

local home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = home .. "/.config/hypr/scripts"
local Touchpad_Device = "asue140d:00-04f3:31bc-touchpad"

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true, description = "decrease keyboard brightness" })
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true, description = "increase keyboard brightness" })
hl.bind("XF86Launch1",           hl.dsp.exec_cmd("rog-control-center"),                      { description = "ASUS Armory crate" })
hl.bind("XF86Launch3",           hl.dsp.exec_cmd("asusctl led-mode -n"),                     { description = "switch keyboard RGB profile" })
hl.bind("XF86Launch4",           hl.dsp.exec_cmd("asusctl profile -n"),                      { description = "switch fan profile" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"),    { repeating = true, description = "decrease monitor brightness" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"),    { repeating = true, description = "increase monitor brightness" })
hl.bind("XF86TouchpadToggle",    hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"),              { description = "toggle touchpad" })

-- Screenshot keybindings using F6
hl.bind(mainMod .. " + F6",          hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"),    { description = "screenshot now" })
hl.bind(mainMod .. " + SHIFT + F6",  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),   { description = "screenshot area" })
hl.bind(mainMod .. " + CTRL + F6",   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),    { description = "screenshot in 5s" })
hl.bind(mainMod .. " + ALT + F6",    hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"),   { description = "screenshot in 10s" })
hl.bind("ALT + F6",                  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "screenshot active window" })

hl.device({
    name = Touchpad_Device,
    enabled = true,
})
