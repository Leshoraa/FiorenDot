#!/usr/bin/env python3
# =============================================================================
# PinchZoom.py – Continuous 2-Finger Gestures for Hyprland:
#   1. Super + 2-Finger Pinch:
#      → Continuous Desktop Zoom (cursor:zoom_factor)
#   2. Super + Alt + 2-Finger Pinch:
#      → Continuous 2D Resize for Floating Window (X and Y independently)
#
# HOW IT WORKS:
#   • Reads raw MT (Multi-Touch) events PASSIVELY – cursor is NOT affected.
#   • Super held: desktop zoom tracks 2-finger spread ratio smoothly.
#   • Super + Alt held: floating window resizes in width (X) and height (Y)
#     proportional to horizontal & vertical finger spread (centered).
#   • No modifiers held: normal touchpad scroll and gestures are untouched.
#   • Writes updates directly via Hyprland IPC UNIX socket at ~40 fps.
#
# Requires: python-evdev
# =============================================================================

import asyncio
import math
import subprocess
import json
import sys
import os
import signal
import socket
import time
import evdev
from evdev import ecodes

# ─── Config ───────────────────────────────────────────────────────────────────
TOUCHPAD_DEVICE = os.environ.get("TOUCHPAD_DEVICE", "auto")

# Desktop Zoom range
ZOOM_MIN        = 1.0    # minimum zoom (1 = normal)
ZOOM_MAX        = 5.0    # maximum zoom
EXPONENT        = 1.0    # zoom response curve (1.0 = linear)

# Floating Window Resize settings
WINDOW_RESIZE_SCALE_X = 0.85  # Screen pixels per touchpad unit (horizontal)
WINDOW_RESIZE_SCALE_Y = 0.85  # Screen pixels per touchpad unit (vertical)
MIN_WINDOW_W          = 200   # Minimum window width in px
MIN_WINDOW_H          = 150   # Minimum window height in px

# Minimum distance between fingers to begin tracking (touchpad units)
MIN_DIST        = 25

# Update throttle interval (seconds). ~40 fps = 0.025s
THROTTLE_S      = 0.025

# ─── State ────────────────────────────────────────────────────────────────────
class Slot:
    __slots__ = ("x", "y", "tid")
    def __init__(self):
        self.x   = None
        self.y   = None
        self.tid = -1   # -1 = empty

# ─── Hyprland IPC ─────────────────────────────────────────────────────────────
_sock_path: str | None = None

def get_hypr_socket() -> str | None:
    global _sock_path
    if _sock_path and os.path.exists(_sock_path):
        return _sock_path

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        run_dir = f"/run/user/{os.getuid()}/hypr"
        if os.path.exists(run_dir):
            entries = os.listdir(run_dir)
            if entries:
                sig = entries[0]
    if sig:
        candidate = f"/run/user/{os.getuid()}/hypr/{sig}/.socket.sock"
        if os.path.exists(candidate):
            _sock_path = candidate
            return _sock_path
    return None

def hypr_cmd(cmd: str) -> str:
    sock = get_hypr_socket()
    if sock:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(0.2)
                s.connect(sock)
                s.sendall(cmd.encode("utf-8"))
                resp = b""
                while True:
                    chunk = s.recv(4096)
                    if not chunk:
                        break
                    resp += chunk
                return resp.decode("utf-8")
        except Exception:
            pass
    # Fallback to hyprctl
    try:
        parts = cmd.split(" ", 1)
        res = subprocess.check_output(
            ["hyprctl", parts[0], parts[1]],
            timeout=0.3,
            stderr=subprocess.DEVNULL
        )
        return res.decode("utf-8")
    except Exception:
        return ""

_zoom_cache: float | None = None

def get_zoom() -> float:
    global _zoom_cache
    try:
        raw = hypr_cmd("j/getoption cursor:zoom_factor")
        if raw:
            data = json.loads(raw)
            if "float" in data:
                _zoom_cache = float(data["float"])
                return _zoom_cache
    except Exception:
        pass

    try:
        raw = subprocess.check_output(
            ["hyprctl", "getoption", "cursor:zoom_factor", "-j"],
            timeout=0.3,
            stderr=subprocess.DEVNULL
        )
        _zoom_cache = float(json.loads(raw)["float"])
    except Exception:
        pass
    return _zoom_cache if _zoom_cache is not None else 1.0

def set_zoom(val: float):
    global _zoom_cache
    val = max(ZOOM_MIN, min(ZOOM_MAX, val))
    # Snap to exactly 1.0 to avoid floating drift
    if abs(val - 1.0) < 0.03:
        val = 1.0
    if _zoom_cache is not None and abs(val - _zoom_cache) < 0.005:
        return   # skip if no meaningful change
    _zoom_cache = val
    hypr_cmd(f"keyword cursor:zoom_factor {val:.4f}")

# ─── Window / Monitor Queries ─────────────────────────────────────────────────
def get_target_floating_window() -> dict | None:
    # 1. Active window if floating
    try:
        raw_act = hypr_cmd("j/activewindow")
        if raw_act:
            act = json.loads(raw_act)
            if act.get("floating") and not act.get("fullscreen") and act.get("mapped"):
                return act
    except Exception:
        pass

    # 2. Window under cursor on current workspace or any floating on active workspace
    try:
        raw_cur = hypr_cmd("j/cursorpos")
        raw_clients = hypr_cmd("j/clients")
        raw_ws = hypr_cmd("j/activeworkspace")
        if raw_clients:
            clients = json.loads(raw_clients)
            ws_id = json.loads(raw_ws).get("id") if raw_ws else None
            cx, cy = None, None
            if raw_cur:
                cur = json.loads(raw_cur)
                cx, cy = cur.get("x"), cur.get("y")

            # Check floating window containing cursor on active workspace
            if cx is not None and cy is not None:
                for c in clients:
                    if not (c.get("floating") and not c.get("fullscreen") and c.get("mapped")):
                        continue
                    if ws_id is not None and c.get("workspace", {}).get("id") != ws_id:
                        continue
                    at = c.get("at", [0, 0])
                    sz = c.get("size", [0, 0])
                    if at[0] <= cx <= at[0] + sz[0] and at[1] <= cy <= at[1] + sz[1]:
                        return c

            # Fallback: any floating window on active workspace
            for c in clients:
                if c.get("floating") and not c.get("fullscreen") and c.get("mapped"):
                    if ws_id is not None and c.get("workspace", {}).get("id") == ws_id:
                        return c
    except Exception:
        pass
    return None

def get_active_monitor_bounds() -> tuple[int, int, int, int]:
    try:
        raw = hypr_cmd("j/monitors")
        if raw:
            mons = json.loads(raw)
            for m in mons:
                if m.get("focused"):
                    scale = m.get("scale", 1.0)
                    w = int(m.get("width", 1920) / scale)
                    h = int(m.get("height", 1080) / scale)
                    x = int(m.get("x", 0) / scale)
                    y = int(m.get("y", 0) / scale)
                    return x, y, w, h
    except Exception:
        pass
    return 0, 0, 1920, 1080

# ─── Keyboard & Modifier Detection ───────────────────────────────────────────
SUPER_KEYS = {ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA}
ALT_KEYS   = {ecodes.KEY_LEFTALT,  ecodes.KEY_RIGHTALT}

_keyboards: dict[str, evdev.InputDevice] = {}
_last_kbd_scan: float = 0.0

def update_keyboards():
    global _keyboards, _last_kbd_scan
    now = time.monotonic()
    if now - _last_kbd_scan < 3.0 and _keyboards:
        return
    _last_kbd_scan = now

    current_paths = set(evdev.list_devices())
    for p in list(_keyboards.keys()):
        if p not in current_paths:
            try:
                _keyboards[p].close()
            except Exception:
                pass
            del _keyboards[p]

    for p in current_paths:
        if p not in _keyboards:
            try:
                dev = evdev.InputDevice(p)
                caps = dev.capabilities()
                if ecodes.EV_KEY in caps:
                    keys = caps[ecodes.EV_KEY]
                    if any(k in SUPER_KEYS for k in keys) or any(k in ALT_KEYS for k in keys):
                        _keyboards[p] = dev
                    else:
                        dev.close()
                else:
                    dev.close()
            except Exception:
                pass

def get_modifiers() -> tuple[bool, bool]:
    update_keyboards()
    super_down = False
    alt_down = False
    for path, kbd in list(_keyboards.items()):
        try:
            active = kbd.active_keys()
            if not super_down and any(k in SUPER_KEYS for k in active):
                super_down = True
            if not alt_down and any(k in ALT_KEYS for k in active):
                alt_down = True
            if super_down and alt_down:
                break
        except (OSError, IOError):
            try:
                kbd.close()
            except Exception:
                pass
            _keyboards.pop(path, None)
        except Exception:
            pass
    return super_down, alt_down

# ─── Touchpad Helpers ─────────────────────────────────────────────────────────
def find_touchpad() -> str:
    if TOUCHPAD_DEVICE != "auto" and os.path.exists(TOUCHPAD_DEVICE):
        return TOUCHPAD_DEVICE

    candidates = []
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            caps = dev.capabilities()
            if ecodes.EV_ABS in caps:
                abs_codes = [c[0] if isinstance(c, tuple) else c for c in caps[ecodes.EV_ABS]]
                if ecodes.ABS_MT_SLOT in abs_codes and ecodes.ABS_MT_POSITION_X in abs_codes:
                    if "touchpad" in dev.name.lower():
                        dev.close()
                        return path
                    candidates.append(path)
            dev.close()
        except Exception:
            pass
    if candidates:
        return candidates[0]
    return "/dev/input/event8"

def finger_deltas(slots: list[Slot]) -> tuple[float, float, float]:
    active = [s for s in slots if s.tid != -1 and s.x is not None and s.y is not None]
    if len(active) < 2:
        return 0.0, 0.0, 0.0
    s0, s1 = active[0], active[1]
    dx = abs(s1.x - s0.x)
    dy = abs(s1.y - s0.y)
    d  = math.hypot(s1.x - s0.x, s1.y - s0.y)
    return dx, dy, d

def active_count(slots: list[Slot]) -> int:
    return sum(1 for s in slots if s.tid != -1 and s.x is not None and s.y is not None)

# ─── Main Loop ────────────────────────────────────────────────────────────────
async def run_listener():
    MAX_SLOTS = 10

    while True:
        dev_path = find_touchpad()
        try:
            dev = evdev.InputDevice(dev_path)
        except FileNotFoundError:
            print(f"[PinchGestures] ✗ Device not found: {dev_path}, retrying in 3s...", flush=True)
            await asyncio.sleep(3.0)
            continue
        except PermissionError:
            print(f"[PinchGestures] ✗ Permission denied for {dev_path} – ensure user is in 'input' group", flush=True)
            sys.exit(1)

        slots = [Slot() for _ in range(MAX_SLOTS)]
        cur_slot = 0

        # Desktop Zoom state
        ref_dist: float | None = None
        ref_zoom: float | None = None

        # Floating Window Resize state
        win_addr: str | None = None
        win_w_ref: int = 0
        win_h_ref: int = 0
        win_x_ref: int = 0
        win_y_ref: int = 0
        win_dx_ref: float | None = None
        win_dy_ref: float | None = None
        win_last_w: int = 0
        win_last_h: int = 0
        mon_bounds: tuple[int, int, int, int] = (0, 0, 1920, 1080)

        last_apply: float = 0.0

        print(f"[PinchGestures] ✓ Listening on {dev.name} ({dev_path})", flush=True)
        print(f"[PinchGestures]   • Super + Pinch: Desktop Zoom ({ZOOM_MIN}×–{ZOOM_MAX}×)", flush=True)
        print(f"[PinchGestures]   • Super + Alt + Pinch: Floating Window 2D Resize (X & Y)", flush=True)

        try:
            async for event in dev.async_read_loop():
                # ── Track MT slots ───────────────────────────────────────────
                if event.type == ecodes.EV_ABS:
                    code = event.code
                    if code == ecodes.ABS_MT_SLOT:
                        cur_slot = min(event.value, MAX_SLOTS - 1)
                    elif code == ecodes.ABS_MT_TRACKING_ID:
                        slots[cur_slot].tid = event.value
                        if event.value == -1:          # finger lifted
                            slots[cur_slot].x = None
                            slots[cur_slot].y = None
                    elif code == ecodes.ABS_MT_POSITION_X:
                        slots[cur_slot].x = event.value
                    elif code == ecodes.ABS_MT_POSITION_Y:
                        slots[cur_slot].y = event.value

                # ── On sync, evaluate gestures ───────────────────────────────
                elif event.type == ecodes.EV_SYN and event.code == ecodes.SYN_REPORT:
                    n = active_count(slots)
                    super_down, alt_down = get_modifiers()

                    # ── MODE 1: RESIZE FLOATING WINDOW (Super + Alt + 2 Fingers) ──
                    if n == 2 and super_down and alt_down:
                        # Reset desktop zoom tracking if previously active
                        if ref_dist is not None:
                            ref_dist = None
                            ref_zoom = None

                        # When in Phantomat overview, disable window resize so it does not clash
                        # with Phantomat's overview zoom in/out or window movement
                        if os.path.exists("/tmp/phantom_active"):
                            if win_addr is not None:
                                win_addr = None
                                win_dx_ref = None
                                win_dy_ref = None
                            continue

                        dx, dy, d = finger_deltas(slots)
                        if d < MIN_DIST:
                            continue

                        if win_addr is None:
                            target = get_target_floating_window()
                            if target:
                                win_addr = target.get("address")
                                win_w_ref = target.get("size", [800, 600])[0]
                                win_h_ref = target.get("size", [800, 600])[1]
                                win_x_ref = target.get("at", [100, 100])[0]
                                win_y_ref = target.get("at", [100, 100])[1]
                                win_dx_ref = dx
                                win_dy_ref = dy
                                win_last_w = win_w_ref
                                win_last_h = win_h_ref
                                mon_bounds = get_active_monitor_bounds()
                            continue

                        # Compute size based on horizontal and vertical finger spread
                        delta_dx = dx - win_dx_ref
                        delta_dy = dy - win_dy_ref

                        mon_x, mon_y, mon_w, mon_h = mon_bounds
                        max_w = max(MIN_WINDOW_W, mon_w - 20)
                        max_h = max(MIN_WINDOW_H, mon_h - 40)

                        new_w = max(MIN_WINDOW_W, min(max_w, int(win_w_ref + delta_dx * WINDOW_RESIZE_SCALE_X)))
                        new_h = max(MIN_WINDOW_H, min(max_h, int(win_h_ref + delta_dy * WINDOW_RESIZE_SCALE_Y)))

                        # Symmetric resize around center
                        new_x = win_x_ref - int((new_w - win_w_ref) / 2)
                        new_y = win_y_ref - int((new_h - win_h_ref) / 2)

                        # Keep within monitor bounds
                        new_x = max(mon_x + 10, min(mon_x + mon_w - new_w - 10, new_x))
                        new_y = max(mon_y + 30, min(mon_y + mon_h - new_h - 10, new_y))

                        now = time.monotonic()
                        if (abs(new_w - win_last_w) >= 3 or abs(new_h - win_last_h) >= 3) and (now - last_apply >= THROTTLE_S):
                            batch_cmd = f"[[BATCH]]dispatch resizewindowpixel exact {new_w} {new_h},address:{win_addr} ; dispatch movewindowpixel exact {new_x} {new_y},address:{win_addr}"
                            hypr_cmd(batch_cmd)
                            win_last_w = new_w
                            win_last_h = new_h
                            last_apply = now

                    # ── MODE 2: DESKTOP ZOOM (Super + 2 Fingers) ───────────────
                    elif n == 2 and super_down and not alt_down:
                        # Reset window resize tracking if previously active
                        if win_addr is not None:
                            win_addr = None
                            win_dx_ref = None
                            win_dy_ref = None

                        # When in Phantomat overview, disable desktop zoom so it does not clash
                        if os.path.exists("/tmp/phantom_active"):
                            if ref_dist is not None:
                                ref_dist = None
                                ref_zoom = None
                            continue

                        dx, dy, d = finger_deltas(slots)
                        if d < MIN_DIST:
                            continue

                        if ref_dist is None:
                            ref_dist = d
                            ref_zoom = get_zoom()
                            continue

                        ratio = d / ref_dist
                        if EXPONENT != 1.0:
                            ratio = ratio ** EXPONENT
                        new_zoom = ref_zoom * ratio

                        now = time.monotonic()
                        if now - last_apply >= THROTTLE_S:
                            set_zoom(new_zoom)
                            last_apply = now

                    # ── IDLE / RESET ──────────────────────────────────────────
                    else:
                        if ref_dist is not None:
                            ref_dist = None
                            ref_zoom = None
                        if win_addr is not None:
                            win_addr = None
                            win_dx_ref = None
                            win_dy_ref = None

        except (OSError, IOError) as e:
            print(f"[PinchGestures] Device disconnected ({e}), re-detecting in 2s...", flush=True)
            try:
                dev.close()
            except Exception:
                pass
            await asyncio.sleep(2.0)
        except asyncio.CancelledError:
            try:
                dev.close()
            except Exception:
                pass
            break

async def main():
    update_keyboards()
    await run_listener()

if __name__ == "__main__":
    def _shutdown(*_):
        print("\n[PinchGestures] Shutting down…", flush=True)
        set_zoom(1.0)
        for k in _keyboards.values():
            try:
                k.close()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT,  _shutdown)

    asyncio.run(main())
