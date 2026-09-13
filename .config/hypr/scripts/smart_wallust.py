#!/usr/bin/env python3
import sys
import os
import json
import re
import colorsys
import subprocess

def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h / 360.0, l / 100.0, s / 100.0)
    ir = max(0, min(255, int(round(r * 255))))
    ig = max(0, min(255, int(round(g * 255))))
    ib = max(0, min(255, int(round(b * 255))))
    return f"#{ir:02x}{ig:02x}{ib:02x}"

def generate_palette(img_path):
    # Use ImageMagick to get up to 32 quantized color clusters
    cmd = ['magick', f'{img_path}[0]', '-resize', '128x128!', '-colors', '32', '-unique-colors', 'txt:-']
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or not res.stdout.strip():
        return None

    colors = []
    for line in res.stdout.strip().split('\n'):
        m = re.search(r'\((\d+),\s*(\d+),\s*(\d+)(?:,\s*\d+)?\)', line)
        if m:
            r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
            colors.append((r, g, b))

    if not colors:
        return None

    # Tonal & Hue population analysis
    hue_weights = {}
    total_sat = 0
    total_luma = 0

    for r, g, b in colors:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        h_deg = round(h * 360)
        s_pct = s * 100.0
        l_pct = l * 100.0
        luma = 0.299 * r + 0.587 * g + 0.114 * b
        total_sat += s_pct
        total_luma += luma

        # Weighting: prioritize colors that are not pitch black or blown-out white
        weight = (s_pct + 10) * (1.0 - abs(l_pct - 50.0) / 50.0)
        bucket = int((h_deg // 15) * 15) % 360
        hue_weights[bucket] = hue_weights.get(bucket, 0) + weight

    avg_sat = total_sat / len(colors)
    if avg_sat < 12.0 or not hue_weights or max(hue_weights.values()) == 0:
        dom_hue = 220
        base_sat = 15.0
    else:
        dom_hue = max(hue_weights.items(), key=lambda x: x[1])[0]
        base_sat = max(35.0, min(80.0, avg_sat))

    # Eliminate greenish/cyan-toska undertones for blue wallpapers:
    # Hues between 175 and 212 are cyan/aquamarine (looks greenish).
    # Shift them to 220 (pure royal/sky blue) so blue is ALWAYS pure blue!
    if 175 <= dom_hue <= 212:
        dom_hue = 220

    H = dom_hue

    # Pure Monochromatic Tonal Palette (100% harmonized to dominant wallpaper hue)
    bg = hsl_to_hex(H, min(18.0, base_sat * 0.25), 8.0)     # Deep dark surface
    fg = hsl_to_hex(H, min(14.0, base_sat * 0.20), 92.0)    # Crisp tinted off-white
    
    # UI Tonal roles (Berserk logo, keys, prompt, borders, waybar)
    c14 = hsl_to_hex(H, base_sat, 72.0)             # Brightest highlight (Logo, Starship pill 1)
    c6  = hsl_to_hex(H, base_sat * 0.90, 75.0)      # Fastfetch keys
    c12 = hsl_to_hex(H, base_sat * 0.95, 62.0)      # Primary active (Window border, Waybar pill)
    c13 = hsl_to_hex(H, base_sat * 0.85, 65.0)      # Fastfetch username / title
    c4  = hsl_to_hex(H, base_sat * 0.80, 52.0)      # Mid accent
    c10 = hsl_to_hex(H, base_sat * 0.75, 48.0)      # Starship pill 2 / secondary border
    c2  = hsl_to_hex(H, base_sat * 0.65, 42.0)      # Deeper tonal shade for fastfetch dots
    c8  = hsl_to_hex(H, min(16.0, base_sat * 0.25), 38.0) # Inactive / surface gray

    # Utility CLI accents (harmonized with H but distinct for git status)
    c1 = hsl_to_hex((H + 180) % 360, min(70.0, base_sat * 0.8), 58.0) # Complementary accent
    c9 = hsl_to_hex((H + 180) % 360, min(80.0, base_sat * 0.9), 68.0)
    c3 = hsl_to_hex((H + 60) % 360, min(65.0, base_sat * 0.75), 58.0)  # Analogous warm
    c11 = hsl_to_hex((H + 60) % 360, min(75.0, base_sat * 0.85), 68.0)
    c5 = hsl_to_hex((H + 30) % 360, min(70.0, base_sat * 0.8), 60.0)

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
        print(f"Warning: wallust cs failed, falling back to wallust run", file=sys.stderr)
        subprocess.run(['wallust', 'run', '-s', '-w', img_path])

if __name__ == '__main__':
    main()
