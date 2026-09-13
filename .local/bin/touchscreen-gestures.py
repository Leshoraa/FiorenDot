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
    gesture_triggered = False
    start_time = 0
    start_positions = {}

    threshold_mm = 25.0  # 25 mm (2.5 cm) swipe distance threshold

    while True:
        try:
            for e in dev.events():
                slot = dev.value(libevdev.EV_ABS.ABS_MT_SLOT) or 0

                if e.matches(libevdev.EV_ABS.ABS_MT_TRACKING_ID):
                    if e.value != -1:
                        # Finger down
                        x = dev.value(libevdev.EV_ABS.ABS_MT_POSITION_X) or 0
                        y = dev.value(libevdev.EV_ABS.ABS_MT_POSITION_Y) or 0
                        active_touches[slot] = {'x': x, 'y': y}
                        if len(active_touches) in (3, 4) and not gesture_triggered:
                            start_time = time.time()
                            start_positions = {s: dict(v) for s, v in active_touches.items()}
                    else:
                        # Finger up
                        if slot in active_touches:
                            del active_touches[slot]
                        if len(active_touches) == 0:
                            gesture_triggered = False
                            start_positions.clear()

                elif e.matches(libevdev.EV_ABS.ABS_MT_POSITION_X):
                    if slot in active_touches:
                        active_touches[slot]['x'] = e.value
                elif e.matches(libevdev.EV_ABS.ABS_MT_POSITION_Y):
                    if slot in active_touches:
                        active_touches[slot]['y'] = e.value

                if len(active_touches) in (3, 4) and not gesture_triggered and len(start_positions) in (3, 4):
                    elapsed = time.time() - start_time
                    if elapsed < 0.8:  # 800ms window
                        common_slots = [s for s in start_positions if s in active_touches]
                        if len(common_slots) == len(start_positions):
                            deltas_x_mm = [(active_touches[s]['x'] - start_positions[s]['x']) / res_x for s in common_slots]
                            deltas_y_mm = [(active_touches[s]['y'] - start_positions[s]['y']) / res_y for s in common_slots]

                            avg_dx = sum(deltas_x_mm) / len(deltas_x_mm)
                            avg_dy = sum(deltas_y_mm) / len(deltas_y_mm)

                            fingers = len(start_positions)

                            if abs(avg_dy) > threshold_mm and abs(avg_dy) > abs(avg_dx) * 1.3:
                                gesture_triggered = True
                                if avg_dy < -threshold_mm:
                                    # Swipe UP
                                    if fingers == 3:
                                        subprocess.run(['hyprctl', 'dispatch', 'global', 'quickshell:overviewToggle'])
                                    elif fingers == 4:
                                        subprocess.run(['swaync-client', '-t', '-sw'])
                                elif avg_dy > threshold_mm:
                                    # Swipe DOWN
                                    if fingers == 3:
                                        subprocess.run(['hyprctl', 'dispatch', 'togglespecialworkspace'])
                                    elif fingers == 4:
                                        subprocess.run(['bash', '-c', 'pkill -x rofi || rofi -show drun'])

                            elif abs(avg_dx) > threshold_mm and abs(avg_dx) > abs(avg_dy) * 1.3:
                                gesture_triggered = True
                                if avg_dx < -threshold_mm:
                                    # Swipe LEFT
                                    if fingers == 3:
                                        subprocess.run(['hyprctl', 'dispatch', 'workspace', '+1'])
                                    elif fingers == 4:
                                        subprocess.run(['hyprctl', 'dispatch', 'movetoworkspace', '+1'])
                                elif avg_dx > threshold_mm:
                                    # Swipe RIGHT
                                    if fingers == 3:
                                        subprocess.run(['hyprctl', 'dispatch', 'workspace', '-1'])
                                    elif fingers == 4:
                                        subprocess.run(['hyprctl', 'dispatch', 'movetoworkspace', '-1'])
        except Exception:
            time.sleep(0.05)

if __name__ == '__main__':
    main()
