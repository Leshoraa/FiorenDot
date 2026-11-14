#!/usr/bin/env python3
# =============================================================================
# PinchZoom.py – Continuous 2-Finger Pinch-to-Zoom for Hyprland
#
# HOW IT WORKS:
#   • Activates ONLY when the Super (Mod4/Windows) key is held down.
#   • Reads raw MT (Multi-Touch) events PASSIVELY – cursor is NOT affected.
#   • When 2 fingers touch while Super is held, records reference distance & zoom.
#   • As fingers move, computes: new_zoom = ref_zoom × (cur_dist / ref_dist)
#     → Ratio-based: zoom tracks finger spread 1:1, naturally smooth.
#   • Writes cursor:zoom_factor via Hyprland IPC socket (or hyprctl) at ~40 fps.
#   • When Super is not held, touchpad performs normal 2-finger scroll/gestures.
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

ZOOM_MIN        = 1.0    # minimum zoom (1 = normal)
ZOOM_MAX        = 5.0    # maximum zoom

# Fingers must be at least this far apart (in touchpad units) to start tracking
MIN_DIST        = 25

# How often to push zoom to Hyprland (seconds). ~40 fps = 0.025s
THROTTLE_S      = 0.025

# Exponent for zoom feel. 1.0 = linear, 1.2 = slightly boosted at extremes
EXPONENT        = 1.0

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

# ─── Keyboard / Super Key Detection ───────────────────────────────────────────
SUPER_KEYS = {ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA}
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
                    if ecodes.KEY_LEFTMETA in keys or ecodes.KEY_RIGHTMETA in keys:
                        _keyboards[p] = dev
                    else:
                        dev.close()
                else:
                    dev.close()
            except Exception:
                pass

def is_super_pressed() -> bool:
    update_keyboards()
    for path, kbd in list(_keyboards.items()):
        try:
            active = kbd.active_keys()
            if any(k in SUPER_KEYS for k in active):
                return True
        except (OSError, IOError):
            try:
                kbd.close()
            except Exception:
                pass
            _keyboards.pop(path, None)
        except Exception:
            pass
    return False

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

def finger_dist(slots: list[Slot]) -> float:
    active = [s for s in slots if s.tid != -1 and s.x is not None and s.y is not None]
    if len(active) < 2:
        return 0.0
    s0, s1 = active[0], active[1]
    return math.hypot(s1.x - s0.x, s1.y - s0.y)

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
            print(f"[PinchZoom] ✗ Device not found: {dev_path}, retrying in 3s...", flush=True)
            await asyncio.sleep(3.0)
            continue
        except PermissionError:
            print(f"[PinchZoom] ✗ Permission denied for {dev_path} – ensure user is in 'input' group", flush=True)
            sys.exit(1)

        slots = [Slot() for _ in range(MAX_SLOTS)]
        cur_slot = 0
        ref_dist: float | None = None
        ref_zoom: float | None = None
        last_apply: float = 0.0

        print(f"[PinchZoom] ✓ Listening on {dev.name} ({dev_path})", flush=True)
        print(f"[PinchZoom]   Hold Super + 2-Finger Pinch to zoom ({ZOOM_MIN}×–{ZOOM_MAX}×)", flush=True)

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

                # ── On sync, evaluate pinch ──────────────────────────────────
                elif event.type == ecodes.EV_SYN and event.code == ecodes.SYN_REPORT:
                    n = active_count(slots)

                    # Only zoom if exactly 2 fingers are touching AND Super key is held
                    if n == 2 and is_super_pressed():
                        d = finger_dist(slots)
                        if d < MIN_DIST:
                            continue   # fingers too close together – ignore

                        if ref_dist is None:
                            # Pinch starts: snapshot reference distance and current zoom
                            ref_dist = d
                            ref_zoom = get_zoom()
                            continue

                        # ── RATIO-BASED zoom ──────────────────────────────────
                        ratio = d / ref_dist
                        if EXPONENT != 1.0:
                            ratio = ratio ** EXPONENT
                        new_zoom = ref_zoom * ratio

                        now = time.monotonic()
                        if now - last_apply >= THROTTLE_S:
                            set_zoom(new_zoom)
                            last_apply = now

                    else:
                        # Not 2 fingers or Super is not held – reset pinch tracking state
                        if ref_dist is not None:
                            ref_dist = None
                            ref_zoom = None

        except (OSError, IOError) as e:
            print(f"[PinchZoom] Device disconnected ({e}), re-detecting in 2s...", flush=True)
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
        print("\n[PinchZoom] Shutting down…", flush=True)
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
