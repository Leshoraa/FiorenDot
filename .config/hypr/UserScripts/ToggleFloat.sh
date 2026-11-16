#!/usr/bin/env python3
import subprocess
import json
import time
import sys

def run_cmd(args):
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def get_active_window():
    try:
        out = subprocess.check_output(['hyprctl', 'activewindow', '-j'])
        return json.loads(out)
    except Exception:
        return {}

def main():
    win = get_active_window()
    if not win or 'class' not in win:
        run_cmd(['hyprctl', 'dispatch', 'togglefloating'])
        return

    win_class = win.get('class', '').lower()
    is_floating = win.get('floating', False)

    if is_floating:
        # Sedang floating -> UNFLOAT (Tile)
        run_cmd(['hyprctl', 'dispatch', 'togglefloating'])
        
        if 'scrcpy' in win_class:
            time.sleep(0.06)
            win_tiled = get_active_window()
            if win_tiled:
                w, h = win_tiled.get('size', [0, 0])
                x, y = win_tiled.get('at', [0, 0])
                if h > 0:
                    # Rasio layar HP Redmi Note 13 Pro (1220x2712 ~ 0.4498)
                    target_w = int(h * (1220 / 2712))
                    delta = w - target_w
                    if delta > 30:
                        # Jika jendela di sebelah kanan, geser border ke kanan (+delta)
                        if x > 100:
                            run_cmd(['hyprctl', 'dispatch', '--', 'resizeactive', str(delta), '0'])
                        else:
                            run_cmd(['hyprctl', 'dispatch', '--', 'resizeactive', str(-delta), '0'])
    else:
        # Sedang tiled -> FLOAT
        run_cmd(['hyprctl', 'dispatch', 'togglefloating'])
        if 'scrcpy' in win_class:
            run_cmd(['hyprctl', 'dispatch', 'resizeactive', 'exact', '382', '850'])
            run_cmd(['hyprctl', 'dispatch', 'centerwindow'])
        else:
            run_cmd(['hyprctl', 'dispatch', 'resizeactive', 'exact', '795', '482'])
            run_cmd(['hyprctl', 'dispatch', 'centerwindow'])

if __name__ == '__main__':
    main()
