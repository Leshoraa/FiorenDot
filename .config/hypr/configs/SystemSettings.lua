-- Author: Fioren (@Leshoraa) (Hyprland 0.57+ Lua Migration) | Base: JaKooLit
-- Default System Settings (migrated from SystemSettings.conf)

hl.config({
    dwindle = {
        preserve_split = true,
        smart_resizing = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.5,
    },

    scrolling = {
        column_width = 0.5,
        direction = "right",
        fullscreen_on_one_column = true,
        follow_focus = true,
        wrap_focus = true,
    },

    general = {
        resize_on_border = true,
        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        sensitivity = 0,
        numlock_by_default = false,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing = false,
            natural_scroll = false,
            clickfinger_behavior = true,
            middle_button_emulation = true,
            tap_to_click = true,
            drag_lock = 1,
        },

        touchdevice = {
            enabled = false,
        },

        tablet = {
            transform = 0,
            left_handed = false,
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 10,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        enable_swallow = false,
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_anr_dialog = true,
        anr_missed_pings = 15,
        allow_session_lock_restore = true,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = 0,
    },

    debug = {
        vfr = true,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = false,
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
        inactive_timeout = 3,
        hide_on_key_press = true,
        hide_on_touch = true,
    },
})
