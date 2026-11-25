#!/usr/bin/env python3
# FiorenDot - Smart Toggle Maximize
# Author: Fioren (@Leshoraa)
# Toggles maximize (fullscreen 1) and ensures returning to normal tiled (not floating)

import subprocess
import json
import time
import sys

def get_active_window():
    try:
        out = subprocess.check_output(['hyprctl', 'activewindow', '-j'], timeout=0.5)
        return json.loads(out)
    except Exception:
        return {}

def hypr_eval(code):
    subprocess.run(['hyprctl', 'eval', code], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    win = get_active_window()
    if not win or 'address' not in win:
        hypr_eval('hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))')
        return

    addr = win.get('address')
    win_class = win.get('class', '').lower()
    # Hyprland fullscreen modes: 0 = normal, 1 = maximized, 2 = fullscreen
    is_fullscreen = win.get('fullscreen', 0)
    is_floating = win.get('floating', False)

    if is_fullscreen > 0:
        # Maximized / fullscreen -> restore normal state
        if is_fullscreen == 1:
            hypr_eval('hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))')
        else:
            hypr_eval('hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset" }))')

        # Unfloat back to tiled (except scrcpy)
        if is_floating and 'scrcpy' not in win_class:
            time.sleep(0.04)
            cur = get_active_window()
            if cur.get('address') == addr and cur.get('floating', False):
                hypr_eval(f'hl.dispatch(hl.dsp.window.float({{ action = "toggle", window = "address:{addr}" }}))')
    else:
        # Normal -> maximize
        hypr_eval('hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))')

if __name__ == '__main__':
    main()
