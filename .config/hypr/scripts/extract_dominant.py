#!/usr/bin/env python3
import sys
import os
import subprocess
import re
import colorsys
import json
import hashlib

def hsl_to_hex(h, s, l):
    h = h % 360
    s = max(0.0, min(100.0, s))
    l = max(0.0, min(100.0, l))
    r, g, b = colorsys.hls_to_rgb(h / 360.0, l / 100.0, s / 100.0)
    ir = max(0, min(255, int(round(r * 255))))
    ig = max(0, min(255, int(round(g * 255))))
    ib = max(0, min(255, int(round(b * 255))))
    return f"#{ir:02x}{ig:02x}{ib:02x}"

def generate_palette(img_path):
    # 1. Histogram pixel population count
    cmd = ['magick', f'{img_path}[0]', '-sample', '128x128!', '-colors', '48', '-format', '%c', 'histogram:info:']
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or not res.stdout.strip():
        return None

    total_px = 0
    chroma_px = 0
    hue_pop = [0.0] * 360
    clusters = []

    for line in res.stdout.strip().split('\n'):
        m = re.search(r'^\s*(\d+):.*#([0-9A-Fa-f]{6})', line)
        if not m:
            continue
        cnt = int(m.group(1))
        hex_str = m.group(2)
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        h_deg = round(h * 360) % 360
        s_pct = s * 100.0
        l_pct = l * 100.0
        clusters.append((cnt, hex_str, h_deg, s_pct, l_pct))
        total_px += cnt

        # Filter out extreme crushed blacks and blown-out whites from hue dominance,
        # weighting by saturation so vivid accents (like sunset clouds) take precedence over dark/dull shadows
        if 8 < l_pct < 92 and s_pct > 12:
            hue_pop[h_deg] += cnt * (s_pct ** 1.3)
            chroma_px += cnt
        elif 4 < l_pct < 96 and s_pct > 6:
            chroma_px += cnt

    if not clusters:
        return None

    # Smooth hue population with +-15 deg window (human eye perception)
    smooth_pop = [0.0] * 360
    for h in range(360):
        for nh in range(h - 15, h + 16):
            smooth_pop[h] += hue_pop[nh % 360]

    is_mono = (chroma_px / total_px < 0.035) if total_px > 0 else True

    if is_mono:
        # Monochrome / grayscale wallpaper
        bg = "#101115"
        fg = "#e6e8ee"
        c14 = "#ffffff"       # Berserk logo / pill 1
        c12 = "#c5c8d4"       # Window border
        c10 = "#4a4e5c"       # Pill 2 (dir)
        c6  = "#d0d3de"       # Fastfetch keys
        c13 = "#a6abbb"       # Title / username
        c8  = "#383b46"       # Inactive border
        c0, c7, c15 = bg, fg, fg
        c1, c9  = "#c46060", "#df7070"
        c2      = "#509e75"
        c3, c11 = "#b89c56", "#d2b568"
        c4      = "#5b7ec4"
        c5      = "#9c68b8"
    else:
        # WARNA PALING BANYAK (DOMINANT HUE BY PIXEL POPULATION)
        dom_h = max(range(360), key=lambda h: smooth_pop[h])

        # If dominant hue lands on the red/coral boundary (345..360 or 0..5),
        # nudge towards warm sunset orange (14 deg) so warm clouds produce vibrant orange instead of pinkish white
        if dom_h >= 345 or dom_h <= 5:
            dom_h = 14

        # Average saturation of dominant hue
        dom_sat_sum = sum(
            s_pct * cnt for cnt, _, h_deg, s_pct, _ in clusters
            if min(abs(h_deg - dom_h), 360 - abs(h_deg - dom_h)) <= 25 and s_pct > 6
        )
        dom_cnt_sum = sum(
            cnt for cnt, _, h_deg, s_pct, _ in clusters
            if min(abs(h_deg - dom_h), 360 - abs(h_deg - dom_h)) <= 25 and s_pct > 6
        )
        raw_s = (dom_sat_sum / dom_cnt_sum) if dom_cnt_sum > 0 else 20.0
        ui_s = max(38.0, min(75.0, raw_s * 1.35))

        # Check for genuine secondary accent if present in wallpaper (must be visible and meaningful)
        sec_candidates = []
        for cnt, _, h_deg, s_pct, l_pct in clusters:
            diff = min(abs(h_deg - dom_h), 360 - abs(h_deg - dom_h))
            # Must be clearly visible (not dark shadow, not blown white), saturated, and distinct
            if diff >= 45 and 18.0 <= l_pct <= 82.0 and s_pct >= 22.0:
                if (cnt / chroma_px >= 0.08) or (cnt / total_px >= 0.025):
                    sec_candidates.append((cnt, h_deg, s_pct, l_pct))

        if sec_candidates:
            sec_candidates.sort(key=lambda x: x[0], reverse=True)
            sec_h = sec_candidates[0][1]
            has_real_sec = True
        else:
            has_real_sec = False
            # When image is monochromatic/duotone, use harmonious analogous tone (no random green or noise!)
            if dom_h >= 320 or dom_h <= 30:
                sec_h = (dom_h + 20) % 360  # Warm coral / crimson rose
            else:
                sec_h = (dom_h + 25) % 360

        # Check if there is a prominent dark cluster (shadow/background of wallpaper)
        dark_clusters = [
            (cnt, hex_str, h_deg, s_pct, l_pct)
            for cnt, hex_str, h_deg, s_pct, l_pct in clusters
            if 3.0 < l_pct <= 22.0 and s_pct > 6.0
        ]
        dark_h = dom_h
        bg_sat = max(18.0, min(36.0, raw_s * 1.1))
        bg_l = 8.0

        if dark_clusters:
            top_dark = max(dark_clusters, key=lambda x: x[0])
            if top_dark[0] / total_px > 0.15:
                diff = min(abs(top_dark[2] - dom_h), 360 - abs(top_dark[2] - dom_h))
                if diff <= 45 or top_dark[0] / total_px > 0.40:
                    dark_h = top_dark[2]
                    bg_sat = max(16.0, min(38.0, top_dark[3] * 0.75))
                    bg_l = max(5.0, min(8.5, top_dark[4] * 1.05))

        bg = hsl_to_hex(dark_h, bg_sat, bg_l)
        fg = hsl_to_hex(dom_h, min(15.0, raw_s * 0.25), 92.5)

        # Natural, painterly UI saturation & lightness (prevents neon or washed-out white/pastel look)
        if 160 <= dom_h <= 215:
            # Teal / Cyan range: naturally very luminous to human eyes, keep saturation and lightness balanced
            ui_s = max(38.0, min(65.0, raw_s * 1.10))
            l_high = 62.0     # c14 (Logo)
            l_keys = 55.0     # c6 (Fastfetch keys)
            l_border = 48.0   # c12 (Window border & Waybar primary)
            l_mid = 40.0      # c4 (Mid accent)
            l_pill = 32.0     # c10 (Starship dir pill)
            l_shade = 24.0    # c2 (Tonal dot)
        else:
            ui_s = max(58.0, min(85.0, raw_s * 1.60))
            l_high = 60.0
            l_keys = 54.0
            l_border = 48.0
            l_mid = 40.0
            l_pill = 32.0
            l_shade = 24.0

        # Primary UI elements: 100% based on WARNA PALING BANYAK
        c12 = hsl_to_hex(dom_h, ui_s, l_border)
        c14 = hsl_to_hex(dom_h, min(55.0, ui_s * 1.1), l_high)
        c10 = hsl_to_hex(dom_h, ui_s * 0.90, l_pill)
        c6  = hsl_to_hex(dom_h, ui_s * 0.95, l_keys)
        c8  = hsl_to_hex(dark_h, max(16.0, min(28.0, bg_sat * 0.8)), 32.0)
        
        sec_sat = max(32.0, min(65.0, raw_s * 1.05)) if has_real_sec else min(48.0, ui_s * 0.95)
        c13 = hsl_to_hex(sec_h, sec_sat, 62.0)
        c5  = hsl_to_hex(sec_h, sec_sat * 0.85, 56.0)

        if has_real_sec and (340 <= sec_h or sec_h <= 25):
            c1  = hsl_to_hex(sec_h, 55.0, 54.0)
            c9  = hsl_to_hex(sec_h, 65.0, 62.0)
        else:
            c1  = hsl_to_hex(dom_h if (dom_h >= 330 or dom_h <= 20) else 4, 55.0, 54.0)
            c9  = hsl_to_hex(dom_h if (dom_h >= 330 or dom_h <= 20) else 4, 65.0, 62.0)

        c2  = hsl_to_hex(dom_h, ui_s * 0.80, l_shade)

        if has_real_sec and 25 <= sec_h <= 65:
            c3  = hsl_to_hex(sec_h, 60.0, 56.0)
            c11 = hsl_to_hex(sec_h, 70.0, 64.0)
        else:
            c3  = hsl_to_hex(42, 55.0, 56.0)
            c11 = hsl_to_hex(42, 65.0, 64.0)

        c4  = hsl_to_hex(dom_h, ui_s, l_mid)
        c0, c7, c15 = bg, fg, fg

    palette = {
        'wallpaper': img_path,
        'special': {'background': bg, 'foreground': fg, 'cursor': fg},
        'colors': {
            'color0': c0, 'color1': c1, 'color2': c2, 'color3': c3,
            'color4': c4, 'color5': c5, 'color6': c6, 'color7': c7,
            'color8': c8, 'color9': c9, 'color10': c10, 'color11': c11,
            'color12': c12, 'color13': c13, 'color14': c14, 'color15': c15
        }
    }
    return palette

def main():
    if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
        img_path = os.path.abspath(sys.argv[1])
    else:
        link = os.path.expanduser('~/.config/rofi/.current_wallpaper')
        if os.path.islink(link) or os.path.isfile(link):
            img_path = os.path.realpath(link)
        else:
            sys.exit(1)

    cache_dir = os.path.expanduser('~/.cache/wallust/palettes')
    os.makedirs(cache_dir, exist_ok=True)

    # Cache key by path and modification time for instant reuse
    mtime = int(os.path.getmtime(img_path))
    hash_key = hashlib.md5(f"{img_path}_{mtime}_v6".encode()).hexdigest()
    theme_file = os.path.join(cache_dir, f"{hash_key}.json")

    if not os.path.isfile(theme_file):
        palette = generate_palette(img_path)
        if not palette:
            subprocess.run(['wallust', 'run', '-s', img_path])
            return
        with open(theme_file, 'w') as f:
            json.dump(palette, f, indent=2)

    # Apply via wallust cs (takes ~13ms)
    subprocess.run(['wallust', 'cs', '-s', '-f', 'pywal', theme_file])

if __name__ == '__main__':
    main()
