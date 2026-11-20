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

def run_cmd(args):
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    win = get_active_window()
    if not win or 'address' not in win:
        run_cmd(['hyprctl', 'dispatch', 'fullscreen', '1'])
        return

    addr = win.get('address')
    win_class = win.get('class', '').lower()
    # Hyprland fullscreen modes: 0 = normal, 1 = maximized, 2 = fullscreen
    is_fullscreen = win.get('fullscreen', 0)
    is_floating = win.get('floating', False)

    if is_fullscreen > 0:
        # Sedang maximize / fullscreen -> Kembalikan ke normal
        if is_fullscreen == 1:
            run_cmd(['hyprctl', 'dispatch', 'fullscreen', '1'])
        else:
            run_cmd(['hyprctl', 'dispatch', 'fullscreen', '0'])

        # Jika jendela dalam status floating, kembalikan menjadi normal tiled (kecuali window khusus seperti scrcpy)
        if is_floating and 'scrcpy' not in win_class:
            time.sleep(0.04)
            cur = get_active_window()
            if cur.get('address') == addr and cur.get('floating', False):
                run_cmd(['hyprctl', 'dispatch', 'togglefloating', f'address:{addr}'])
    else:
        # Sedang normal -> Maximize
        run_cmd(['hyprctl', 'dispatch', 'fullscreen', '1'])

if __name__ == '__main__':
    main()
