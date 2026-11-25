-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Default Keybinds (migrated to Hyprland 0.57+ Lua)

local home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

local defaults = require("UserConfigs.01-UserDefaults")
local term = defaults.term
local files = defaults.files

-- Common shortcuts
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "app launcher" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd('xdg-open "https://"'), { description = "open default browser" })
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewToggle"), { description = "desktop overview" })
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term), { description = "Open terminal" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(files), { description = "file manager" })

-- Features / Extras
hl.bind(mainMod .. " + H",               hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"),                                         { description = "help / cheat sheet" })
hl.bind(mainMod .. " + ALT + R",         hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"),                                          { description = "refresh bar and menus" })
hl.bind(mainMod .. " + ALT + E",         hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"),                                        { description = "emoji menu" })
hl.bind(mainMod .. " + S",               hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"),                                       { description = "web search" })
hl.bind(mainMod .. " + CTRL + S",        hl.dsp.exec_cmd("rofi -show window"),                                                  { description = "window switcher" })
hl.bind(mainMod .. " + ALT + O",         hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"),                                       { description = "toggle blur mode (optimized/ultra)" })
hl.bind(mainMod .. " + SHIFT + G",       hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"),                                         { description = "toggle game mode" })
hl.bind(mainMod .. " + ALT + L",         hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"),                                     { description = "toggle master/dwindle layout" })
hl.bind(mainMod .. " + ALT + V",         hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"),                                      { description = "clipboard manager" })
hl.bind(mainMod .. " + CTRL + R",        hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh"),                                { description = "rofi theme selector" })
hl.bind(mainMod .. " + CTRL + SHIFT + R",hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"), { description = "rofi theme selector (modified)" })

hl.bind(mainMod .. " + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "fullscreen" })
hl.bind(mainMod .. " + ALT + F",        hl.dsp.window.fullscreen({ mode = "maximized" }),  { description = "maximize window" })
hl.bind(mainMod .. " + SPACE", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 795, y = 482, exact = true }))
    hl.dispatch(hl.dsp.window.center())
end)
hl.bind(mainMod .. " + CTRL + SPACE",   hl.dsp.exec_cmd(scriptsDir .. "/FloatAll.sh"),     { description = "Float all windows in active workspace" })
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh " .. term), { description = "DropDown terminal" })

-- Desktop zooming / Magnifier (native Lua)
hl.bind(mainMod .. " + ALT + mouse_down", function()
    local z = hl.get_config("cursor.zoom_factor") or 1.0
    hl.config({ cursor = { zoom_factor = z * 1.25 } })
end, { description = "zoom in" })
hl.bind(mainMod .. " + ALT + mouse_up", function()
    local z = hl.get_config("cursor.zoom_factor") or 1.0
    local next_z = z / 1.25
    hl.config({ cursor = { zoom_factor = next_z < 1.0 and 1.0 or next_z } })
end, { description = "zoom out" })
hl.bind(mainMod .. " + ALT + mouse:274", function()
    hl.config({ cursor = { zoom_factor = 1.0 } })
end, { description = "reset zoom" })

-- Waybar
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"),                  { description = "toggle waybar on/off" })
hl.bind(mainMod .. " + CTRL + B",       hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"),         { description = "waybar styles menu" })
hl.bind(mainMod .. " + ALT + B",        hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"),         { description = "waybar layout menu" })

-- Screen recorder
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(scriptsDir .. "/Recorder.sh"))

-- UserScripts extras
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(UserScripts .. "/RofiBeats.sh"),                { description = "online music" })
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(UserScripts .. "/WallpaperSelect.sh"),          { description = "select wallpaper" })
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd(UserScripts .. "/WallpaperEffects.sh"),         { description = "wallpaper effects" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperRandom.sh"),          { description = "random wallpaper" })
hl.bind(mainMod .. " + CTRL + O",  hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "toggle active window opacity" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"),                  { description = "search keybinds" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"),                { description = "animations menu" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(UserScripts .. "/ScreenOCR.sh"),                { description = "screen ocr to clipboard" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(UserScripts .. "/RofiProjects.sh"),             { description = "quick project switcher" })
hl.bind("ALT_L + SHIFT_L",         hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"),      { locked = true, non_consuming = true, description = "switch keyboard layout globally" })
hl.bind("SHIFT_L + ALT_L",         hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"),    { locked = true, non_consuming = true, description = "switch keyboard layout per-window" })
hl.bind(mainMod .. " + ALT + C",   hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh"),                 { description = "calculator" })

-- Move current workspaces to monitors
hl.bind(mainMod .. " + CTRL + F9",  hl.dsp.workspace.move({ monitor = "l" }), { description = "move workspace to left monitor" })
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }), { description = "move workspace to right monitor" })
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }), { description = "move workspace to up monitor" })
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }), { description = "move workspace to down monitor" })

-- System
hl.bind("CTRL + ALT + Delete",       hl.dsp.exit(),                                                  { description = "exit Hyprland" })
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.window.close(),                                          { description = "close active window" })
hl.bind(mainMod .. " + Q",           hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"),         { description = "Terminate active process" })
hl.bind("ALT + F4",                  hl.dsp.no_op())
hl.bind(mainMod .. " + SHIFT + L",   hl.dsp.exec_cmd("hyprlock"),                                    { description = "lock screen" })
hl.bind(mainMod .. " + CTRL + SHIFT + L", hl.dsp.exec_cmd(scriptsDir .. "/Hypridle.sh toggle"),      { description = "Toggle Hypridle" })
hl.bind("ALT + P",                   hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"),                   { description = "powermenu" })
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("swaync-client -t -sw"),                        { description = "notification panel" })
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh"),       { description = "Quick settings menu" })

-- Master / Dwindle / Monocle layout actions
hl.bind(mainMod .. " + CTRL + D",      hl.dsp.layout("removemaster"),   { description = "remove master" })
hl.bind(mainMod .. " + I",             hl.dsp.layout("addmaster"),      { description = "add master" })
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })
hl.bind("XF86PowerOff",                hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"))
hl.bind(mainMod .. " + SHIFT + I",     hl.dsp.layout("togglesplit"),    { description = "toggle split (dwindle)" })
hl.bind(mainMod .. " + P",             hl.dsp.window.pseudo(),          { description = "toggle pseudo (dwindle)" })
hl.bind(mainMod .. " + M",             hl.dsp.layout("splitratio 0.3"), { description = "set split ratio 0.3" })

-- Dummy overrides
hl.bind(mainMod .. " + ALT + up",    hl.dsp.no_op())
hl.bind(mainMod .. " + ALT + down",  hl.dsp.no_op())
hl.bind(mainMod .. " + ALT + left",  hl.dsp.no_op())
hl.bind(mainMod .. " + ALT + right", hl.dsp.no_op())
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.no_op())

-- Special Keys / Hot Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"),        { repeating = true, locked = true, description = "volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"),        { repeating = true, locked = true, description = "volume down" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true, description = "toggle mic mute" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"),     { locked = true, description = "toggle mute" })
hl.bind("XF86Sleep",            hl.dsp.exec_cmd("systemctl suspend"),                     { locked = true, description = "sleep" })
hl.bind("XF86Rfkill",           hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"),        { locked = true, description = "airplane mode" })

-- Media controls
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "play/pause" })
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "pause" })
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "play" })
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"),   { locked = true, description = "next track" })
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"),   { locked = true, description = "previous track" })
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"),  { locked = true, description = "stop" })

-- Screenshot keybindings
hl.bind("Print",                        hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"),    { description = "screenshot now" })
hl.bind(mainMod .. " + SHIFT + Print",  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),   { description = "screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print",   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),    { description = "screenshot in 5s" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "screenshot in 10s" })
hl.bind("ALT + Print",                  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "screenshot active window" })
hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "screenshot (swappy)" })

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "resize left (-50)" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50,  y = 0, relative = true }), { repeating = true, description = "resize right (+50)" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "resize up (-50)" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 50,  relative = true }), { repeating = true, description = "resize down (+50)" })

-- Move windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.exec_cmd(scriptsDir .. "/MoveWindow.sh l"), { repeating = true, description = "move window left" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd(scriptsDir .. "/MoveWindow.sh r"), { repeating = true, description = "move window right" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.exec_cmd(scriptsDir .. "/MoveWindow.sh u"), { repeating = true, description = "move window up" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.exec_cmd(scriptsDir .. "/MoveWindow.sh d"), { repeating = true, description = "move window down" })

-- Group
hl.bind(mainMod .. " + G",          hl.dsp.group.toggle(),                      { description = "toggle group" })
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next(),                        { description = "change active in group" })
hl.bind(mainMod .. " + CTRL + H",   hl.dsp.window.move({ out_of_group = true }),{ description = "Move active out of group" })

-- Smart arrow focus (native Lua: Scrolling, Monocle, or Standard)
hl.bind(mainMod .. " + left", function()
    local lay = hl.get_config("general.layout")
    if lay == "scrolling" then
        hl.dispatch(hl.dsp.layout("focus l"))
    elseif lay == "monocle" then
        hl.dispatch(hl.dsp.layout("cycleprev"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "left" }))
    end
end, { description = "focus left" })

hl.bind(mainMod .. " + right", function()
    local lay = hl.get_config("general.layout")
    if lay == "scrolling" then
        hl.dispatch(hl.dsp.layout("focus r"))
    elseif lay == "monocle" then
        hl.dispatch(hl.dsp.layout("cyclenext"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "right" }))
    end
end, { description = "focus right" })

hl.bind(mainMod .. " + up", function()
    local lay = hl.get_config("general.layout")
    if lay == "monocle" then
        hl.dispatch(hl.dsp.layout("cycleprev"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "up" }))
    end
end, { description = "focus up" })

hl.bind(mainMod .. " + down", function()
    local lay = hl.get_config("general.layout")
    if lay == "monocle" then
        hl.dispatch(hl.dsp.layout("cyclenext"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "down" }))
    end
end, { description = "focus down" })

-- Workspaces navigation
hl.bind(mainMod .. " + Tab",         hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh next"), { description = "next workspace" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh prev"), { description = "previous workspace" })

hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mainMod .. " + CTRL + L",   hl.dsp.dpms("off"))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd("codium"))

-- Toggle Touchscreen
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(UserScripts .. "/TouchscreenToggle.sh toggle"), { description = "Toggle Touchscreen" })

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "move to special workspace" })
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special(),             { description = "toggle special workspace" })

-- Workspace 1..10 via keycodes (code:10 .. code:19)
for ws = 1, 10 do
    local code = "code:" .. tostring(ws + 9)
    hl.bind(mainMod .. " + " .. code,           hl.dsp.focus({ workspace = ws }),                       { description = "workspace " .. ws })
    hl.bind(mainMod .. " + SHIFT + " .. code,   hl.dsp.window.move({ workspace = ws }),                 { description = "move to workspace " .. ws })
    hl.bind(mainMod .. " + CTRL + " .. code,    hl.dsp.window.move({ workspace = ws, follow = false }), { description = "move silently to workspace " .. ws })
end

hl.bind(mainMod .. " + bracketleft",          hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh prev"),         { description = "previous workspace" })
hl.bind(mainMod .. " + bracketright",         hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh next"),         { description = "next workspace" })
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }),                       { description = "move to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }),                       { description = "move to next workspace" })
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }),       { description = "move silently to previous workspace" })
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }),       { description = "move silently to next workspace" })

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh next"), { description = "next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh prev"), { description = "previous workspace" })
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh next"), { description = "next workspace" })
hl.bind(mainMod .. " + comma",      hl.dsp.exec_cmd(scriptsDir .. "/WorkspaceNav.sh prev"), { description = "previous workspace" })

-- Move/resize windows with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "resize window" })
