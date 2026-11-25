#!/usr/bin/env python3
import subprocess
import json
import time
import sys

def hypr_eval(code):
    subprocess.run(['hyprctl', 'eval', code], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def get_active_window():
    try:
        out = subprocess.check_output(['hyprctl', 'activewindow', '-j'])
        return json.loads(out)
    except Exception:
        return {}

def main():
    win = get_active_window()
    if not win or 'class' not in win:
        hypr_eval('hl.dispatch(hl.dsp.window.float({ action = "toggle" }))')
        return

    win_class = win.get('class', '').lower()
    is_floating = win.get('floating', False)

    if is_floating:
        # Floating -> tile
        hypr_eval('hl.dispatch(hl.dsp.window.float({ action = "toggle" }))')
        
        if 'scrcpy' in win_class:
            time.sleep(0.06)
            win_tiled = get_active_window()
            if win_tiled:
                w, h = win_tiled.get('size', [0, 0])
                x, y = win_tiled.get('at', [0, 0])
                if h > 0:
                    # Redmi Note 13 Pro aspect ratio (1220x2712 ~ 0.4498)
                    target_w = int(h * (1220 / 2712))
                    delta = w - target_w
                    if delta > 30:
                        # Shift split edge right when tiled on the right side (+delta)
                        dx = delta if x > 100 else -delta
                        hypr_eval(f'hl.dispatch(hl.dsp.window.resize({{ x = {dx}, y = 0, relative = true }}))')
    else:
        # Tiled -> float
        if 'scrcpy' in win_class:
            hypr_eval('hl.dispatch(hl.dsp.window.float({ action = "toggle" })); hl.dispatch(hl.dsp.window.resize({ x = 382, y = 850, exact = true })); hl.dispatch(hl.dsp.window.center())')
        else:
            hypr_eval('hl.dispatch(hl.dsp.window.float({ action = "toggle" })); hl.dispatch(hl.dsp.window.resize({ x = 795, y = 482, exact = true })); hl.dispatch(hl.dsp.window.center())')

if __name__ == '__main__':
    main()
