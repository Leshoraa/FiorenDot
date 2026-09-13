#!/usr/bin/env python3
import sys
import os
import json
import re
import colorsys
import subprocess

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
    """
    Caelestia / Material You (M3) inspired color extraction.
    Uses pixel population histogram + hue-excited neighbor smoothing (+-15 deg)
    to select dominant and secondary tonal palettes that mirror human visual perception.
    """
    # 1. Quantize to 48 color clusters with exact pixel counts (histogram)
    cmd = ['magick', f'{img_path}[0]', '-resize', '150x150!', '-colors', '48', '-format', '%c', 'histogram:info:']
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or not res.stdout.strip():
        return None

    clusters = []
    hue_population = [0.0] * 360
    total_pop = 0

    for line in res.stdout.strip().split('\n'):
        m = re.search(r'^\s*(\d+):.*#([0-9A-Fa-f]{6})', line)
        if m:
            cnt = int(m.group(1))
            hex_str = m.group(2)
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            h_deg = round(h * 360) % 360
            s_pct = s * 100.0
            l_pct = l * 100.0
            clusters.append((cnt, r, g, b, h_deg, s_pct, l_pct))

            # Exclude extreme crushed blacks and blown-out whites from dominating hue calculations
            if 8 < l_pct < 94 and s_pct > 8:
                hue_population[h_deg] += cnt
                total_pop += cnt

    if not clusters:
        return None

    # Fallback if image is completely monochrome / dark
    if total_pop == 0:
        for cnt, r, g, b, h_deg, s_pct, l_pct in clusters:
            hue_population[h_deg] += cnt
            total_pop += cnt

    # 2. Caelestia Hue-Excited Proportions (smooth across +- 15 degrees)
    hue_proportions = [0.0] * 360
    for h in range(360):
        if total_pop > 0:
            prop = hue_population[h] / total_pop
            for nh in range(h - 15, h + 16):
                hue_proportions[nh % 360] += prop

    # 3. Score color clusters (Balance between spatial area & chroma/vibrancy)
    candidates = []
    for cnt, r, g, b, h_deg, s_pct, l_pct in clusters:
        if l_pct < 10 or l_pct > 92 or s_pct < 8:
            continue
        prop = hue_proportions[h_deg]
        # Saturation curve targeting 45-75%
        sat_factor = min(1.0, s_pct / 45.0)
        # Lightness curve peaking around 50%
        light_factor = 1.0 - (abs(l_pct - 50.0) / 50.0) ** 1.6
        # Caelestia formula: 65% area proportion + 35% chroma/vibrancy
        score = (prop * 65.0) + (sat_factor * 35.0) * light_factor
        candidates.append((score, h_deg, s_pct, l_pct))

    candidates.sort(key=lambda x: x[0], reverse=True)

    if not candidates:
        dom_h = 220
        dom_s = 25.0
    else:
        dom_h = candidates[0][1]
        dom_s = max(25.0, min(85.0, candidates[0][2]))

    # 4. Find secondary distinct accent color from the wallpaper
    sec_h = (dom_h + 180) % 360
    sec_s = dom_s * 0.8
    for c in candidates[1:]:
        diff = abs(c[1] - dom_h)
        if diff > 180:
            diff = 360 - diff
        if diff >= 35 and c[2] >= 20.0:
            sec_h = c[1]
            sec_s = max(25.0, min(80.0, c[2]))
            break

    # 5. Build Material Design 3 Tonal Palette
    H = dom_h
    S = dom_s
    H2 = sec_h
    S2 = sec_s

    # Tonal surfaces (subtly tinted dark surface and off-white foreground)
    bg = hsl_to_hex(H, min(16.0, S * 0.22), 8.5)
    fg = hsl_to_hex(H, min(14.0, S * 0.18), 91.5)

    # Primary UI roles (Berserk logo, Starship prompt, Waybar, Active window borders)
    c14 = hsl_to_hex(H, S, 72.0)                   # Highlight / Berserk Logo
    c12 = hsl_to_hex(H, S * 0.95, 62.0)            # Active border / Waybar pill
    c6  = hsl_to_hex(H, S * 0.85, 75.0)            # Fastfetch keys
    c4  = hsl_to_hex(H, S * 0.80, 52.0)            # Mid accent
    c10 = hsl_to_hex(H, S * 0.75, 48.0)            # Secondary border / Starship 2
    c8  = hsl_to_hex(H, min(14.0, S * 0.20), 38.0) # Inactive / surface gray

    # Secondary & Tertiary accents (Username, dots, CLI colors)
    c2  = hsl_to_hex(H2, S2 * 0.85, 55.0)          # Secondary distinct accent (dots / status)
    c13 = hsl_to_hex(H2, S2 * 0.90, 68.0)          # Secondary bright (username)
    c1  = hsl_to_hex((H + 180) % 360, min(75.0, S * 0.85), 58.0) # Complementary warm
    c9  = hsl_to_hex((H + 180) % 360, min(85.0, S * 0.90), 68.0)
    c3  = hsl_to_hex((H + 60) % 360, min(70.0, S * 0.80), 60.0)  # Analogous
    c11 = hsl_to_hex((H + 60) % 360, min(80.0, S * 0.85), 70.0)
    c5  = hsl_to_hex((H2 + 30) % 360, min(75.0, S2 * 0.85), 62.0)

    palette = {
        'wallpaper': img_path,
        'special': {
            'background': bg,
            'foreground': fg,
            'cursor': fg
        },
        'colors': {
            'color0': bg,
            'color1': c1,
            'color2': c2,
            'color3': c3,
            'color4': c4,
            'color5': c5,
            'color6': c6,
            'color7': fg,
            'color8': c8,
            'color9': c9,
            'color10': c10,
            'color11': c11,
            'color12': c12,
            'color13': c13,
            'color14': c14,
            'color15': fg
        }
    }
    return palette

def main():
    if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
        img_path = os.path.abspath(sys.argv[1])
    else:
        # Fallback to current wallpaper links
        link = os.path.expanduser('~/.config/rofi/.current_wallpaper')
        if os.path.islink(link) or os.path.isfile(link):
            img_path = os.path.realpath(link)
        else:
            print("Error: No wallpaper provided and fallback not found", file=sys.stderr)
            sys.exit(1)

    palette = generate_palette(img_path)
    if not palette:
        print(f"Warning: Smart extraction failed for {img_path}, falling back to wallust run", file=sys.stderr)
        subprocess.run(['wallust', 'run', '-s', '-w', img_path])
        return

    cache_dir = os.path.expanduser('~/.cache/wallust')
    os.makedirs(cache_dir, exist_ok=True)
    theme_file = os.path.join(cache_dir, 'smart_scheme.json')
    with open(theme_file, 'w') as f:
        json.dump(palette, f, indent=2)

    # Apply via wallust cs
    res = subprocess.run(['wallust', 'cs', '-s', '-f', 'pywal', theme_file])
    if res.returncode != 0:
        print("Warning: wallust cs failed, falling back to wallust run", file=sys.stderr)
        subprocess.run(['wallust', 'run', '-s', '-w', img_path])

if __name__ == '__main__':
    main()
