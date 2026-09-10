#!/usr/bin/env python3
"""
WaybarCava2.sh — Audio visualizer with MPRIS state synchronization for Waybar.

Matches the hide/show behavior of custom/title:
- Hidden when no music is playing or paused directly in the media player app.
- Shown when music is playing.
- Shown (flat bars) when paused via Waybar manual pause (/tmp/waybar_manual_pause).
"""

import os
import sys
import time
import signal
import atexit
import tempfile
import threading
import subprocess

BARS = "▁▂▃▄▅▆▇█"
TRANS = str.maketrans({
    '0': '▁', '1': '▂', '2': '▃', '3': '▄',
    '4': '▅', '5': '▆', '6': '▇', '7': '█',
    ';': ''
})
FLAT_BARS = "▁" * 10
MANUAL_PAUSE_FILE = "/tmp/waybar_manual_pause"

running = True
state_lock = threading.Lock()
current_status = "Stopped"
status_changed = threading.Event()

def get_playerctl_status():
    try:
        res = subprocess.run(
            ["playerctl", "status"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=1
        )
        if res.returncode == 0:
            return res.stdout.strip()
    except Exception:
        pass
    return "Stopped"

def player_monitor():
    global current_status, running
    while running:
        try:
            proc = subprocess.Popen(
                ["playerctl", "-a", "metadata", "--format", "{{status}}", "-F"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True
            )
            while running:
                line = proc.stdout.readline()
                if not line:
                    break
                st = line.strip()
                if st:
                    with state_lock:
                        if current_status != st:
                            current_status = st
                            status_changed.set()
            try:
                proc.terminate()
                proc.wait(timeout=0.2)
            except Exception:
                pass
        except Exception:
            pass
        
        if running:
            with state_lock:
                new_st = get_playerctl_status()
                if current_status != new_st:
                    current_status = new_st
                    status_changed.set()
            time.sleep(1)

def periodic_verifier():
    global current_status, running
    last_manual = os.path.exists(MANUAL_PAUSE_FILE)
    while running:
        time.sleep(0.5)
        cur_manual = os.path.exists(MANUAL_PAUSE_FILE)
        if cur_manual != last_manual:
            last_manual = cur_manual
            status_changed.set()
        
        st = get_playerctl_status()
        with state_lock:
            if current_status != st:
                current_status = st
                status_changed.set()

def main():
    global running, current_status
    
    # Single-instance guard
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    pidfile = os.path.join(runtime_dir, "waybar-cava2.pid")
    if os.path.exists(pidfile):
        try:
            with open(pidfile, "r") as f:
                oldpid = int(f.read().strip())
            os.kill(oldpid, signal.SIGTERM)
            time.sleep(0.1)
        except Exception:
            pass
    try:
        with open(pidfile, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass

    # Unique temp cava config
    tmp_conf = tempfile.NamedTemporaryFile(mode="w", prefix="waybar-cava2-", suffix=".conf", delete=False)
    conf_path = tmp_conf.name
    tmp_conf.write("""[general]
framerate = 45
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
""")
    tmp_conf.close()

    cava_proc = None

    def cleanup():
        nonlocal cava_proc
        try:
            if cava_proc:
                cava_proc.terminate()
                cava_proc.wait(timeout=0.2)
        except Exception:
            try:
                cava_proc.kill()
            except Exception:
                pass
        try:
            os.remove(conf_path)
        except Exception:
            pass
        try:
            os.remove(pidfile)
        except Exception:
            pass

    atexit.register(cleanup)

    def sig_handler(signum, frame):
        global running
        running = False
        cleanup()
        sys.exit(0)

    try:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except Exception:
        pass

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    # Initial status
    with state_lock:
        current_status = get_playerctl_status()

    t1 = threading.Thread(target=player_monitor, daemon=True)
    t1.start()
    t2 = threading.Thread(target=periodic_verifier, daemon=True)
    t2.start()

    last_mode = None  # "playing", "paused", "hidden"

    while running:
        with state_lock:
            st = current_status

        manual_pause = os.path.exists(MANUAL_PAUSE_FILE)

        if st == "Playing":
            if last_mode != "playing":
                if cava_proc is None or cava_proc.poll() is not None:
                    cava_proc = subprocess.Popen(
                        ["cava", "-p", conf_path],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.DEVNULL,
                        text=True,
                        bufsize=1
                    )
                last_mode = "playing"

            try:
                line = cava_proc.stdout.readline()
                if not line:
                    time.sleep(0.02)
                    continue
                bars = line.translate(TRANS).strip()
                if bars:
                    sys.stdout.write(f'{{"text":"{bars}","class":"Playing"}}\n')
                    sys.stdout.flush()
            except BrokenPipeError:
                cleanup()
                sys.exit(0)

        elif st == "Paused" and manual_pause:
            if last_mode != "paused":
                if cava_proc and cava_proc.poll() is None:
                    cava_proc.terminate()
                    cava_proc.wait(timeout=0.1)
                    cava_proc = None
                try:
                    sys.stdout.write(f'{{"text":"{FLAT_BARS}","class":"Paused"}}\n')
                    sys.stdout.flush()
                except BrokenPipeError:
                    cleanup()
                    sys.exit(0)
                last_mode = "paused"

            status_changed.wait(timeout=0.5)
            status_changed.clear()

        else:
            # Hidden (Paused directly in app, Stopped, No player)
            if last_mode != "hidden":
                if cava_proc and cava_proc.poll() is None:
                    cava_proc.terminate()
                    cava_proc.wait(timeout=0.1)
                    cava_proc = None
                try:
                    sys.stdout.write('{"text":""}\n')
                    sys.stdout.flush()
                except BrokenPipeError:
                    cleanup()
                    sys.exit(0)
                last_mode = "hidden"

            status_changed.wait(timeout=0.5)
            status_changed.clear()

if __name__ == "__main__":
    main()
