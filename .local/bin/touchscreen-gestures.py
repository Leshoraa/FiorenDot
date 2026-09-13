#!/usr/bin/env python3
import os
import re
import sys
import time
import json
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

def get_screen_transform():
    try:
        res = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.3)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            for m in data:
                if m.get('name') == 'eDP-1':
                    return int(m.get('transform', 0))
    except Exception:
        pass
    return 0

def run_dispatch(cmd_args):
    try:
        subprocess.Popen(cmd_args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as err:
        print(f"Error executing {cmd_args}: {err}", file=sys.stderr)

def main():
    dev_path = find_touchscreen_device()
    if not dev_path or not os.path.exists(dev_path):
        print("Touchscreen device not found.", file=sys.stderr)
        sys.exit(1)

    fd = open(dev_path, 'rb')
    dev = libevdev.Device(fd)

    res_x = 109.0
    res_y = 174.0
    if dev.has(libevdev.EV_ABS.ABS_MT_POSITION_X):
        info_x = dev.absinfo[libevdev.EV_ABS.ABS_MT_POSITION_X]
        if info_x and info_x.resolution:
            res_x = float(info_x.resolution)
    if dev.has(libevdev.EV_ABS.ABS_MT_POSITION_Y):
        info_y = dev.absinfo[libevdev.EV_ABS.ABS_MT_POSITION_Y]
        if info_y and info_y.resolution:
            res_y = float(info_y.resolution)

    # Session tracking variables
    active_touches = {}      # tid -> touch info
    session_touches = {}     # tid -> touch info across current multi-touch sequence
    session_start_time = 0.0
    session_max_fingers = 0
    session_gesture_done = False
    last_trigger_time = 0.0
    cached_transform = 0

    SWIPE_THRESHOLD_MM = 14.0   # ~1.4 cm for intentional swipe
    MIN_FINGER_SWIPE_MM = 7.0   # each active finger must move at least 7mm in that direction
    MAX_TAP_DISP_MM = 8.0       # fingers must stay within 8mm for tap detection

    while True:
        try:
            for e in dev.events():
                # Process atomic touch frame on EV_SYN.SYN_REPORT
                if not e.matches(libevdev.EV_SYN.SYN_REPORT):
                    continue

                now = time.time()

                # Query current active contacts from libevdev slots
                current_contacts = {}
                for slot_idx in range(dev.num_slots):
                    slot = dev.slots[slot_idx]
                    tid = slot[libevdev.EV_ABS.ABS_MT_TRACKING_ID]
                    if tid is not None and tid != -1:
                        x = slot[libevdev.EV_ABS.ABS_MT_POSITION_X]
                        y = slot[libevdev.EV_ABS.ABS_MT_POSITION_Y]
                        if x is not None and y is not None:
                            current_contacts[tid] = (float(x), float(y))

                num_contacts = len(current_contacts)

                if num_contacts > 0:
                    # Session initialization if this is the start of a touch sequence
                    if len(active_touches) == 0:
                        session_start_time = now
                        session_max_fingers = num_contacts
                        session_gesture_done = False
                        session_touches.clear()
                        cached_transform = get_screen_transform()
                    else:
                        session_max_fingers = max(session_max_fingers, num_contacts)

                    # Update contact positions and record max displacements
                    for tid, (x, y) in current_contacts.items():
                        if tid not in active_touches:
                            touch_data = {
                                'start_x': x,
                                'start_y': y,
                                'cur_x': x,
                                'cur_y': y,
                                'max_disp_mm': 0.0,
                            }
                            active_touches[tid] = touch_data
                            session_touches[tid] = touch_data
                        else:
                            touch_data = active_touches[tid]
                            touch_data['cur_x'] = x
                            touch_data['cur_y'] = y
                            dx_mm = (x - touch_data['start_x']) / res_x
                            dy_mm = (y - touch_data['start_y']) / res_y
                            disp = (dx_mm * dx_mm + dy_mm * dy_mm) ** 0.5
                            if disp > touch_data['max_disp_mm']:
                                touch_data['max_disp_mm'] = disp

                    # Remove lifted contacts from active tracking
                    for tid in list(active_touches.keys()):
                        if tid not in current_contacts:
                            del active_touches[tid]

                    # Detect Multi-Finger Swipes while fingers are in motion
                    # Triggerable when 3 or 4 fingers participate and at least 2 are moving together
                    if not session_gesture_done and session_max_fingers in (3, 4) and num_contacts >= 2:
                        if (now - last_trigger_time) > 0.35 and (now - session_start_time) < 1.5:
                            displacements = []
                            for tid, (x, y) in current_contacts.items():
                                t = session_touches.get(tid)
                                if t:
                                    raw_dx = (x - t['start_x']) / res_x
                                    raw_dy = (y - t['start_y']) / res_y

                                    # Coordinate rotation based on Hyprland transform
                                    if cached_transform == 1:
                                        sx, sy = raw_dy, -raw_dx
                                    elif cached_transform == 2:
                                        sx, sy = -raw_dx, -raw_dy
                                    elif cached_transform == 3:
                                        sx, sy = -raw_dy, raw_dx
                                    else:
                                        sx, sy = raw_dx, raw_dy
                                    displacements.append((sx, sy))

                            if len(displacements) >= 2:
                                avg_dx = sum(d[0] for d in displacements) / len(displacements)
                                avg_dy = sum(d[1] for d in displacements) / len(displacements)
                                abs_avg_x = abs(avg_dx)
                                abs_avg_y = abs(avg_dy)

                                # Check Vertical Swipe
                                if abs_avg_y >= SWIPE_THRESHOLD_MM and abs_avg_y > abs_avg_x * 1.2:
                                    if avg_dy < 0 and all(d[1] <= -MIN_FINGER_SWIPE_MM for d in displacements):
                                        # Swipe UP
                                        session_gesture_done = True
                                        last_trigger_time = now
                                        if session_max_fingers == 3:
                                            run_dispatch(['hyprctl', 'dispatch', 'global', 'quickshell:overviewToggle'])
                                        elif session_max_fingers == 4:
                                            run_dispatch(['swaync-client', '-t', '-sw'])
                                    elif avg_dy > 0 and all(d[1] >= MIN_FINGER_SWIPE_MM for d in displacements):
                                        # Swipe DOWN
                                        session_gesture_done = True
                                        last_trigger_time = now
                                        if session_max_fingers == 3:
                                            run_dispatch(['hyprctl', 'dispatch', 'togglespecialworkspace'])
                                        elif session_max_fingers == 4:
                                            run_dispatch(['bash', '-c', 'pkill -x rofi || rofi -show drun'])

                                # Check Horizontal Swipe
                                elif abs_avg_x >= SWIPE_THRESHOLD_MM and abs_avg_x > abs_avg_y * 1.2:
                                    if avg_dx < 0 and all(d[0] <= -MIN_FINGER_SWIPE_MM for d in displacements):
                                        # Swipe LEFT
                                        session_gesture_done = True
                                        last_trigger_time = now
                                        if session_max_fingers == 3:
                                            run_dispatch(['hyprctl', 'dispatch', 'workspace', '+1'])
                                        elif session_max_fingers == 4:
                                            run_dispatch(['hyprctl', 'dispatch', 'movetoworkspace', '+1'])
                                    elif avg_dx > 0 and all(d[0] >= MIN_FINGER_SWIPE_MM for d in displacements):
                                        # Swipe RIGHT
                                        session_gesture_done = True
                                        last_trigger_time = now
                                        if session_max_fingers == 3:
                                            run_dispatch(['hyprctl', 'dispatch', 'workspace', '-1'])
                                        elif session_max_fingers == 4:
                                            run_dispatch(['hyprctl', 'dispatch', 'movetoworkspace', '-1'])

                else:
                    # All fingers have lifted (num_contacts == 0)
                    if len(active_touches) > 0 or len(session_touches) > 0:
                        duration = now - session_start_time

                        # Check 3-finger single tap
                        # Requirements:
                        # - Exactly 3 fingers engaged at peak
                        # - No swipe gesture triggered
                        # - Natural tap duration: 0.05s <= duration <= 0.65s
                        # - Stationary touch: max_disp < 8.0 mm across all contacts
                        # - Debounce interval satisfied
                        if (not session_gesture_done and
                            session_max_fingers == 3 and
                            len(session_touches) in (3, 4) and
                            0.05 <= duration <= 0.65):

                            max_disp = max((t['max_disp_mm'] for t in session_touches.values()), default=0.0)
                            if max_disp < MAX_TAP_DISP_MM:
                                if (now - last_trigger_time) > 0.35:
                                    last_trigger_time = now
                                    run_dispatch([os.path.expanduser('~/.config/hypr/UserScripts/VirtualKeyboardVisibility.sh')])

                        # Reset session tracking
                        active_touches.clear()
                        session_touches.clear()
                        session_max_fingers = 0
                        session_gesture_done = False

        except libevdev.EventsDroppedException:
            try:
                dev.sync()
            except Exception:
                pass
            active_touches.clear()
            session_touches.clear()
            session_max_fingers = 0
            session_gesture_done = False
        except Exception as err:
            print(f"Unexpected error in gesture loop: {err}", file=sys.stderr)
            time.sleep(0.05)

if __name__ == '__main__':
    main()
