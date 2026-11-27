#!/usr/bin/env bash
# Hide TTY cursor/logs cleanly while launching the Wayland session
printf '\033[?25l\033[2J\033[H' 2>/dev/null || true
exec "$@" >"${XDG_RUNTIME_DIR:-/tmp}/hyprland-session.log" 2>&1
