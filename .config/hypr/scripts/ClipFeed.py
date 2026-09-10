#!/usr/bin/env python3
import os
import sys
import signal
import subprocess

signal.signal(signal.SIGPIPE, signal.SIG_DFL)

CACHE_DIR = os.path.expanduser("~/.cache/cliphist_thumbs")
os.makedirs(CACHE_DIR, exist_ok=True)
WALLPAPER = os.path.expanduser("~/.config/rofi/.current_wallpaper_square.png")

def make_thumb(item_id):
    square_path = f"{CACHE_DIR}/{item_id}_square.png"
    if os.path.exists(square_path):
        return square_path
    try:
        p_decode = subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        raw_data, _ = p_decode.communicate(input=f"{item_id}\t".encode("utf-8"), timeout=0.5)
        if raw_data:
            p_magick = subprocess.Popen(
                ["magick", "-", "-gravity", "center", "-crop", "1:1", "+repage", "-resize", "416x416", square_path],
                stdin=subprocess.PIPE
            )
            p_magick.communicate(input=raw_data, timeout=1.0)
            if os.path.exists(square_path):
                return square_path
    except Exception:
        pass
    return None

def main():
    try:
        raw_entries = subprocess.check_output(["cliphist", "list"], timeout=1.0).decode("utf-8", errors="ignore").splitlines()
    except Exception:
        sys.exit(0)

    if not raw_entries:
        sys.exit(0)

    # 1. Ensure the active initial entry (index 0) has a thumbnail ready if it's an image
    top_line = raw_entries[0]
    if "[[ binary data" in top_line:
        parts = top_line.split("\t", 1)
        if parts:
            item_id = parts[0].strip()
            if not os.path.exists(f"{CACHE_DIR}/{item_id}_square.png"):
                make_thumb(item_id)

    # 2. Build output lines with icon metadata instantly
    output_lines = []
    missing_ids = []
    for idx, line in enumerate(raw_entries):
        if not line:
            continue
        parts = line.split("\t", 1)
        item_id = parts[0].strip()
        content = parts[1] if len(parts) > 1 else ""
        is_image = "[[ binary data" in content

        if is_image:
            square_path = f"{CACHE_DIR}/{item_id}_square.png"
            output_lines.append(f"{line}\0icon\x1f{square_path}")
            if idx < 15 and not os.path.exists(square_path):
                missing_ids.append(item_id)
        else:
            output_lines.append(f"{line}\0icon\x1f{WALLPAPER}")

    # 3. Output to Rofi immediately so the window pops up with ZERO delay
    try:
        sys.stdout.write("\n".join(output_lines) + "\n")
        sys.stdout.flush()
        sys.stdout.close()
    except BrokenPipeError:
        sys.exit(0)

    # 4. Background fork to generate any missing recent thumbnails without blocking Rofi
    if missing_ids:
        try:
            pid = os.fork()
            if pid == 0:
                for mid in missing_ids:
                    make_thumb(mid)
                os._exit(0)
        except Exception:
            pass

if __name__ == "__main__":
    main()
