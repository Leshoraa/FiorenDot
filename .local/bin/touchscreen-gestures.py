#!/usr/bin/env python3
import os
import re
import sys
import time
import subprocess
import libevdev

def find_touchscreen_device():
    try:
        with open('/proc/bus/input/devices', 'r') as f:
            content = f.read()
    except Exception:
        return None

    blocks = content.strip().split('\n\n')
    for b in blocks:
        if ('Touchscreen' in b or 'WDHT' in b or 'touchscreen' in b) and 'Stylus' not in b:
            for line in b.split('\n'):
                if line.startswith('H: Handlers='):
                    m = re.search(r'event(\d+)', line)
                    if m:
                        return f"/dev/input/event{m.group(1)}"
    return None

def run_dispatch(cmd_args):
    try:
        subprocess.run(cmd_args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    dev_path = find_touchscreen_device()
    if not dev_path or not os.path.exists(dev_path):
        print(f"Touchscreen device not found.", file=sys.stderr)
        sys.exit(1)

    fd = open(dev_path, 'rb')
    dev = libevdev.Device(fd)

    res_x = 109.0
    res_y = 174.0
    if dev.has(libevdev.EV_ABS.ABS_MT_POSITION_X):
        res_x = float(dev.absinfo[libevdev.EV_ABS.ABS_MT_POSITION_X].resolution or 109.0)
    if dev.has(libevdev.EV_ABS.ABS_MT_POSITION_Y):
        res_y = float(dev.absinfo[libevdev.EV_ABS.ABS_MT_POSITION_Y].resolution or 174.0)

    active_touches = {}
    start_time = 0
    start_cx = 0.0
    start_cy = 0.0
    max_fingers = 0
    gesture_done = False
    last_trigger_time = 0

    THRESHOLD_MM = 12.0  # 12 mm (~1.2 cm) quick and effortless threshold

    while True:
        try:
            for e in dev.events():
                slot = dev.value(libevdev.EV_ABS.ABS_MT_SLOT) or 0

                if e.matches(libevdev.EV_ABS.ABS_MT_TRACKING_ID):
                    if e.value != -1:
                        # Finger down
                        x = dev.value(libevdev.EV_ABS.ABS_MT_POSITION_X) or 0
                        y = dev.value(libevdev.EV_ABS.ABS_MT_POSITION_Y) or 0
                        active_touches[slot] = {'x': float(x), 'y': float(y)}

                        now = time.time()
                        if len(active_touches) == 1:
                            start_time = now
                            start_cx = float(x)
                            start_cy = float(y)
                            max_fingers = 1
                            gesture_done = False
                        else:
                            # Update max fingers and calibrate start centroid during initial touch settling (within 180ms)
                            if (now - start_time) < 0.20:
                                max_fingers = max(max_fingers, len(active_touches))
                                start_cx = sum(t['x'] for t in active_touches.values()) / len(active_touches)
                                start_cy = sum(t['y'] for t in active_touches.values()) / len(active_touches)
                            else:
                                max_fingers = max(max_fingers, len(active_touches))
                    else:
                        # Finger lifted
                        if slot in active_touches:
                            del active_touches[slot]
                        if len(active_touches) == 0:
                            gesture_done = False
                            max_fingers = 0

                elif e.matches(libevdev.EV_ABS.ABS_MT_POSITION_X):
                    if slot in active_touches:
                        active_touches[slot]['x'] = float(e.value)
                elif e.matches(libevdev.EV_ABS.ABS_MT_POSITION_Y):
                    if slot in active_touches:
                        active_touches[slot]['y'] = float(e.value)

                # Check gesture while fingers are in motion
                if not gesture_done and max_fingers in (3, 4) and len(active_touches) >= 2:
                    now = time.time()
                    if (now - last_trigger_time) > 0.35 and (now - start_time) < 1.2:
                        cur_cx = sum(t['x'] for t in active_touches.values()) / len(active_touches)
                        cur_cy = sum(t['y'] for t in active_touches.values()) / len(active_touches)

                        dx_mm = (cur_cx - start_cx) / res_x
                        dy_mm = (cur_cy - start_cy) / res_y

                        abs_x = abs(dx_mm)
                        abs_y = abs(dy_mm)

                        if abs_x >= THRESHOLD_MM or abs_y >= THRESHOLD_MM:
                            gesture_done = True
                            last_trigger_time = now

                            if abs_y > abs_x:
                                # Vertical swipe
                                if dy_mm < 0:
                                    # Swipe UP
                                    if max_fingers == 3:
                                        run_dispatch(['hyprctl', 'dispatch', 'global', 'quickshell:overviewToggle'])
                                    elif max_fingers == 4:
                                        run_dispatch(['swaync-client', '-t', '-sw'])
                                else:
                                    # Swipe DOWN
                                    if max_fingers == 3:
                                        run_dispatch(['hyprctl', 'dispatch', 'togglespecialworkspace'])
                                    elif max_fingers == 4:
                                        run_dispatch(['bash', '-c', 'pkill -x rofi || rofi -show drun'])
                            else:
                                # Horizontal swipe
                                if dx_mm < 0:
                                    # Swipe LEFT
                                    if max_fingers == 3:
                                        run_dispatch(['hyprctl', 'dispatch', 'workspace', '+1'])
                                    elif max_fingers == 4:
                                        run_dispatch(['hyprctl', 'dispatch', 'movetoworkspace', '+1'])
                                else:
                                    # Swipe RIGHT
                                    if max_fingers == 3:
                                        run_dispatch(['hyprctl', 'dispatch', 'workspace', '-1'])
                                    elif max_fingers == 4:
                                        run_dispatch(['hyprctl', 'dispatch', 'movetoworkspace', '-1'])
        except Exception:
            time.sleep(0.02)

if __name__ == '__main__':
    main()
