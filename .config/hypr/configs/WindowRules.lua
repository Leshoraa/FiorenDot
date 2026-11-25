-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Vendor defaults for window rules and layerrules (migrated to Hyprland 0.57+ Lua)

-- Browser tags
local browser_classes = {
    "^([Ff]irefox|org\\.mozilla\\.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$",
    "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$",
    "^(chrome-.+-Default)$",
    "^([Cc]hromium)$",
    "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$",
    "^(Brave-browser(-beta|-dev|-unstable)?)$",
    "^([Tt]horium-browser|[Cc]achy-browser)$",
    "^(zen-alpha|zen)$",
}
for _, cls in ipairs(browser_classes) do
    hl.window_rule({ match = { class = cls }, tag = "+browser" })
end

-- Notif tags
hl.window_rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, tag = "+notif" })

-- Waydroid auto-fullscreen
hl.window_rule({ match = { class = "^([Ww]aydroid)$" }, fullscreen = true })

-- KooL settings tags
hl.window_rule({ match = { title = "^(KooL Quick Cheat Sheet)$" }, tag = "+KooL_Cheat" })
hl.window_rule({ match = { title = "^(KooL Hyprland Settings)$" }, tag = "+KooL_Settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" }, tag = "+KooL-Settings" })

-- Terminal tags
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- Email tags
hl.window_rule({ match = { class = "^([Tt]hunderbird|org\\.gnome\\.Evolution)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu\\.betterbird\\.Betterbird)$" }, tag = "+email" })

-- Project tags
local project_classes = {
    "^(codium|codium-url-handler|VSCodium)$",
    "^(VSCode|code|code-url-handler)$",
    "^(jetbrains-.+)$",
    "^(antigravity|Antigravity|google-chrome-antigravity)$",
    "^(android-studio|android-studio-canary)$",
}
for _, cls in ipairs(project_classes) do
    hl.window_rule({ match = { class = cls }, tag = "+projects" })
end

-- Screenshare tags
hl.window_rule({ match = { class = "^(com\\.obsproject\\.Studio)$" }, tag = "+screenshare" })

-- IM tags
local im_classes = {
    "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$",
    "^([Ff]erdium)$",
    "^([Ww]hatsapp-for-linux)$",
    "^(ZapZap|com\\.rtosta\\.zapzap)$",
    "^(org\\.telegram\\.desktop|io\\.github\\.tdesktop_x64\\.TDesktop)$",
    "^(teams-for-linux)$",
    "^(im\\.riot\\.Riot|Element)$",
}
for _, cls in ipairs(im_classes) do
    hl.window_rule({ match = { class = cls }, tag = "+im" })
end

-- Game tags
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })

-- Gamestore tags
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com\\.heroicgameslauncher\\.hgl)$" }, tag = "+gamestore" })

-- File-manager tags
hl.window_rule({ match = { class = "^([Tt]hunar|org\\.gnome\\.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app\\.drey\\.Warp)$" }, tag = "+file-manager" })

-- Wallpaper, multimedia, settings, viewer tags
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

local settings_classes = {
    "^(wihotspot(-gui)?)$",
    "^([Bb]aobab|org\\.gnome\\.[Bb]aobab)$",
    "^(gnome-disks|wihotspot(-gui)?)$",
    "^(file-roller|org\\.gnome\\.FileRoller)$",
    "^(nm-applet|nm-connection-editor|blueman-manager)$",
    "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|com\\.saivert\\.pwvucontrol)$",
    "^(qt5ct|qt6ct|[Yy]ad)$",
    "(xdg-desktop-portal-gtk)",
    "^(org\\.kde\\.polkit-kde-authentication-agent-1)$",
    "^([Rr]ofi)$",
}
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
for _, cls in ipairs(settings_classes) do
    hl.window_rule({ match = { class = cls }, tag = "+settings" })
end

hl.window_rule({ match = { class = "^(gnome-system-monitor|org\\.gnome\\.SystemMonitor|io\\.missioncenter\\.MissionCenter)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(eog|org\\.gnome\\.Loupe)$" }, tag = "+viewer" })

-- Special override rules
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true, opacity = "1.0" })

-- Position
hl.window_rule({ match = { tag = "KooL_Cheat" }, center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|com\\.saivert\\.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com\\.rtosta\\.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = "72% 7%" })

-- Avoid idle for fullscreen apps
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- Float
hl.window_rule({ match = { tag = "KooL_Cheat" }, float = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true })
hl.window_rule({ match = { tag = "settings" }, float = true })
hl.window_rule({ match = { tag = "viewer" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" }, float = true })
hl.window_rule({ match = { class = "(org\\.gnome\\.Calculator)", title = "(Calculator)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com\\.github\\.rafostar\\.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })

-- Float popups and dialogues
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
hl.window_rule({ match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" }, float = true })
hl.window_rule({ match = { class = "^(com\\.heroicgameslauncher\\.hgl)$", title = "negative:(Heroic Games Launcher)" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, float = true })

hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true, size = "(monitor_w*0.7) (monitor_h*0.6)", center = true })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true, size = "(monitor_w*0.7) (monitor_h*0.6)", center = true })
hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true, size = "(monitor_w*0.7) (monitor_h*0.6)" })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true, center = true, size = "(monitor_w*0.16) (monitor_h*0.12)" })
hl.window_rule({ match = { class = "^(yad)$", title = "^(YAD)$" }, float = true, center = true, size = "(monitor_w*0.2) (monitor_h*0.2)" })

-- Opacity
hl.window_rule({ match = { tag = "browser" }, opacity = "1.0 0.92" })
hl.window_rule({ match = { tag = "projects" }, opacity = "0.96 0.84" })
hl.window_rule({ match = { tag = "im" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.94 0.88" })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org\\.gnome\\.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- Size
hl.window_rule({ match = { tag = "KooL_Cheat" }, size = "(monitor_w*0.65) (monitor_h*0.9)" })
hl.window_rule({ match = { tag = "wallpaper" }, size = "(monitor_w*0.7) (monitor_h*0.7)" })
hl.window_rule({ match = { tag = "settings" }, size = "(monitor_w*0.7) (monitor_h*0.7)" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com\\.rtosta\\.zapzap)$" }, size = "(monitor_w*0.6) (monitor_h*0.7)" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = "(monitor_w*0.6) (monitor_h*0.7)" })

-- Pinning
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true, keep_aspect_ratio = true })

-- Blur & fullscreen
hl.window_rule({ match = { tag = "games" }, no_blur = true, fullscreen = false })

-- IntelliJ focus fix
hl.window_rule({ match = { class = "^(jetbrains-*)" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

-- Layer rules
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.5 })
