#!/usr/bin/env bash
# Author: Fioren (@Leshoraa)
# Cleanly restore display DPMS, wake idle/VFR frame state, and defer audio stack recovery after suspend.

set -u

ensure_dpms_on() {
    # Only dispatch dpms("on") if an active monitor reports dpmsStatus=false,
    # avoiding redundant DRM modesets that cancel active page-flips on amdgpu.
    if hyprctl monitors -j 2>/dev/null | grep -q '"dpmsStatus":[[:space:]]*false'; then
        hyprctl eval 'hl.dispatch(hl.dsp.dpms("on"))' >/dev/null 2>&1 || true
    fi
}

# 1. Immediate DPMS check on wake
ensure_dpms_on

# 2. Gentle input/VFR wake + delayed DPMS guard in background so hypridle never blocks
(
    sleep 0.25
    ensure_dpms_on

    # Nudge pointer by 1px and back to reset ext_idle_notifier (prevents 30s lock DPMS-off
    # firing right after wake) and trigger a fresh compositor frame for VFR/PSR.
    export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/.ydotool_socket}"
    if command -v ydotool >/dev/null 2>&1 && [[ -S "$YDOTOOL_SOCKET" ]]; then
        ydotool mousemove -x 1 -y 0 >/dev/null 2>&1 || true
        ydotool mousemove -x -1 -y 0 >/dev/null 2>&1 || true
    fi

    sleep 0.5
    ensure_dpms_on
) >/dev/null 2>&1 &

# 3. Recover WirePlumber asynchronously without stalling wake/UI
(
    sleep 1.2
    systemctl --user restart wireplumber >/dev/null 2>&1 || true
) >/dev/null 2>&1 &
