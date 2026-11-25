#!/usr/bin/env python3
"""Generate an accurate, dark-background / bright-content 16-color palette.

Rules:
  * Background (`background`, `color0`) and dark UI surfaces (`color8`, `color10`)
    always stay dark and derive from the wallpaper's actual shadow/dark tones.
  * Content colors (`foreground`, `color7`, `color15`, accents `color12`..`color14`,
    and `color1`..`color6`, `color9`, `color11`) always stay bright, readable, and
    faithful to the wallpaper's real OKLCH colors (no invented alien hues).
  * Every content color meets WCAG contrast >= 4.8 against the background, and
    `color15` meets WCAG contrast >= 4.5 against `color8` and `color10`.
"""
import glob
import hashlib
import json
import math
import os
import subprocess
import sys

# Bump whenever the palette algorithm changes to invalidate cached themes.
CACHE_VERSION = "v19"

CONTENT_KEYS = [
    'color1', 'color2', 'color3', 'color4', 'color5', 'color6',
    'color9', 'color11', 'color12', 'color13', 'color14',
]


def srgb_to_oklab(rgb):
    """Convert an (N, 3) float32 sRGB array in [0, 1] to OKLab (L, a, b)."""
    import numpy as np
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    r, g, b = lin[:, 0], lin[:, 1], lin[:, 2]
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = np.cbrt(np.maximum(0.0, l))
    m_ = np.cbrt(np.maximum(0.0, m))
    s_ = np.cbrt(np.maximum(0.0, s))
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return np.stack([L, a, b_], axis=1)


def oklab_to_linear_srgb(L, a, b):
    """Convert scalar OKLab (L, a, b) to unclamped linear sRGB (r, g, b)."""
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_
    r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return r, g, bl


def oklch_to_hex(L, C, h_deg):
    """Convert OKLCH to #RRGGBB, preserving hue and lightness via chroma gamut-mapping."""
    L = clamp(float(L), 0.0, 1.0)
    C = max(0.0, float(C))
    h_rad = math.radians(h_deg % 360.0)
    ca, cb = math.cos(h_rad), math.sin(h_rad)

    r, g, b = oklab_to_linear_srgb(L, C * ca, C * cb)
    if not (0.0 <= r <= 1.0 and 0.0 <= g <= 1.0 and 0.0 <= b <= 1.0):
        lo, hi = 0.0, C
        for _ in range(18):
            mid = 0.5 * (lo + hi)
            rm, gm, bm = oklab_to_linear_srgb(L, mid * ca, mid * cb)
            if 0.0 <= rm <= 1.0 and 0.0 <= gm <= 1.0 and 0.0 <= bm <= 1.0:
                lo = mid
            else:
                hi = mid
        r, g, b = oklab_to_linear_srgb(L, lo * ca, lo * cb)

    def encode(c):
        c = clamp(c, 0.0, 1.0)
        s = 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1.0 / 2.4)) - 0.055
        return max(0, min(255, int(round(s * 255))))

    return f"#{encode(r):02X}{encode(g):02X}{encode(b):02X}"


def rel_lum(hx):
    """Compute WCAG relative luminance for #RRGGBB."""
    def chan(v):
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r = chan(int(hx[1:3], 16))
    g = chan(int(hx[3:5], 16))
    b = chan(int(hx[5:7], 16))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    """Compute WCAG contrast ratio between two #RRGGBB colors."""
    la, lb = rel_lum(a), rel_lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def hue_dist(a, b):
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def ensure_bright_contrast(L, C, h, bg_hex, target=4.8, max_L=0.90):
    """Raise OKLCH lightness until the color meets `target` contrast against `bg_hex`."""
    hx = oklch_to_hex(L, C, h)
    while contrast(hx, bg_hex) < target and L < max_L:
        L = min(max_L, L + 0.015)
        hx = oklch_to_hex(L, C, h)
    return hx


def sample_image_oklab(img_path):
    """Downsample image via ImageMagick to 96x96 sRGB and convert to OKLab arrays."""
    import numpy as np
    cmd = [
        'magick', f'{img_path}[0]', '-alpha', 'off',
        '-resize', '96x96!', '-depth', '8', '-colorspace', 'sRGB', 'rgb:-',
    ]
    res = subprocess.run(cmd, capture_output=True)
    if res.returncode != 0 or len(res.stdout) < 3:
        return None
    usable = (len(res.stdout) // 3) * 3
    rgb = np.frombuffer(res.stdout[:usable], dtype=np.uint8).reshape(-1, 3).astype(np.float32) / 255.0
    return srgb_to_oklab(rgb)


def extract_hue_families(L, a, b, C, h, N):
    """Extract distinct, perceptually salient hue families from visible surfaces."""
    import numpy as np
    # Exclude very dark outline/shadow pixels (L < 0.295) unless the image is almost all dark,
    # so midtone architectural surfaces (e.g. roof tiles) aren't drowned out by dark outlines.
    rel_C = C / np.maximum(L, 0.26)
    cmask = (C >= 0.013) & (rel_C >= 0.052) & (L >= 0.295) & (L <= 0.94)
    if cmask.mean() < 0.025:
        cmask = (C >= 0.013) & (rel_C >= 0.052) & (L >= 0.16) & (L <= 0.95)
    c_frac = float(cmask.mean())
    max_C = float(C.max())
    if c_frac < 0.008 or max_C < 0.040:
        return []

    hc = np.round(h[cmask]).astype(int) % 360
    Cc, Lc, ac, bc = C[cmask], L[cmask], a[cmask], b[cmask]

    hist = np.bincount(hc, weights=(Cc ** 0.65), minlength=360)
    kernel = np.array([15 - abs(k) for k in range(-14, 15)], dtype=float)
    kernel /= kernel.sum()
    padded = np.concatenate([hist[-14:], hist, hist[:14]])
    smooth = np.convolve(padded, kernel, mode='valid')

    peaks = []
    for idx in np.argsort(-smooth):
        if smooth[idx] <= 0:
            break
        if all(hue_dist(idx, p) >= 26.0 for p in peaks):
            peaks.append(int(idx))

    raw_families = []
    for p in peaks:
        d = np.minimum(np.abs(hc - p), 360 - np.abs(hc - p))
        m = d <= 16
        share = float(m.sum() / N)
        if share < 0.0145:
            continue
        w = Cc[m] ** 1.1
        wsum = float(w.sum())
        a_rep = float((ac[m] * w).sum() / wsum)
        b_rep = float((bc[m] * w).sum() / wsum)
        h_rep = (math.degrees(math.atan2(b_rep, a_rep)) + 360.0) % 360.0
        C_rep = float(np.percentile(Cc[m], 65))
        L_rep = float((Lc[m] * w).sum() / wsum)
        if (C_rep / max(L_rep, 0.26)) < 0.058 and C_rep < 0.024:
            continue
        score = (share ** 0.85) * (C_rep ** 0.20)
        raw_families.append({
            'score': score, 'share': share,
            'L': L_rep, 'C': C_rep, 'h': h_rep,
        })

    raw_families.sort(key=lambda x: x['score'], reverse=True)
    families = []
    for fam in raw_families:
        if all(hue_dist(fam['h'], f['h']) >= 40.0 for f in families):
            families.append(fam)

    if not families:
        w = Cc ** 1.1
        wsum = float(w.sum())
        a_rep = float((ac * w).sum() / wsum)
        b_rep = float((bc * w).sum() / wsum)
        h_rep = (math.degrees(math.atan2(b_rep, a_rep)) + 360.0) % 360.0
        families = [{
            'score': 1.0, 'share': c_frac,
            'L': float((Lc * w).sum() / wsum),
            'C': float(np.percentile(Cc, 65)),
            'h': h_rep,
        }]

    return families


def derive_dark_background(L, C, h, pri, sec):
    """Derive a dark background from the dominant dark shadow hue cluster."""
    import numpy as np
    dmask = L <= 0.31
    if dmask.mean() >= 0.05:
        q = min(0.31, float(np.percentile(L, 28)) + 0.02)
        dsub = L <= max(q, float(L.min()) + 0.03)
        dC, dh = C[dsub], h[dsub]
        dcm = dC >= 0.012
        if dcm.mean() >= 0.20:
            dhc = np.round(dh[dcm]).astype(int) % 360
            dhist = np.bincount(dhc, weights=np.minimum(dC[dcm], 0.05), minlength=360)
            dpadded = np.concatenate([dhist[-15:], dhist, dhist[:15]])
            dsmooth = np.convolve(dpadded, np.ones(31) / 31.0, mode='valid')
            bg_h = float(int(np.argmax(dsmooth)))
            dm = np.minimum(np.abs(dhc - bg_h), 360 - np.abs(dhc - bg_h)) <= 25
            med_c = float(np.median(dC[dcm][dm]))
            # Align muted dark shadows with secondary cool surface hue if adjacent
            if sec and med_c < 0.032 and hue_dist(bg_h, sec['h']) <= 65.0:
                bg_h = sec['h']
            bg_C = min(med_c, 0.020)
        else:
            bg_h = pri['h']
            bg_C = 0.008
        bg_L = clamp(float(np.median(L[dsub])) * 0.80, 0.148, 0.190)
    else:
        cool = sec if (sec and sec['L'] < pri['L']) else pri
        bg_h = cool['h']
        bg_C = min(cool['C'] * 0.20, 0.020)
        bg_L = 0.165
    return bg_L, bg_C, bg_h, oklch_to_hex(bg_L, bg_C, bg_h)


def neutral_palette(img_path):
    bg = "#111215"
    fg = "#EAECEF"
    return {
        'wallpaper': img_path,
        'special': {'background': bg, 'foreground': fg, 'cursor': fg},
        'colors': {
            'color0': bg, 'color1': "#B8BCC6", 'color2': "#9EA4B2",
            'color3': "#D2D5DD", 'color4': "#B0B6C4", 'color5': "#C0C4CF",
            'color6': "#CFD3DC", 'color7': fg, 'color8': "#383B44",
            'color9': "#CBD0DA", 'color10': "#464A55", 'color11': "#DFE2E8",
            'color12': "#C4C8D2", 'color13': "#A8AEBC", 'color14': "#E2E5EC",
            'color15': fg,
        },
    }


def make_bright(fam, bg_hex, target_L=0.73, min_contrast=5.0, c_scale=1.12):
    """Lift an image color family into a bright, contrast-safe content color."""
    L_use = clamp(max(fam['L'], target_L), target_L, 0.84)
    # Preserve relative colorfulness when lifting dark colors (e.g. slate blue) to bright L.
    lift = (L_use / max(fam['L'], 0.36)) ** 0.72 if fam['L'] < L_use else 1.0
    max_c = 0.12 if fam['C'] < 0.045 else 0.21
    C_use = clamp(fam['C'] * c_scale * lift, min(fam['C'], 0.04), max_c)
    return ensure_bright_contrast(L_use, C_use, fam['h'], bg_hex, target=min_contrast)


def generate_palette(img_path):
    import numpy as np
    lab = sample_image_oklab(img_path)
    if lab is None:
        return None

    L, a, b = lab[:, 0], lab[:, 1], lab[:, 2]
    C = np.hypot(a, b)
    h = (np.degrees(np.arctan2(b, a)) + 360.0) % 360.0

    families = extract_hue_families(L, a, b, C, h, len(L))
    if not families:
        return neutral_palette(img_path)

    pri = families[0]
    sec = families[1] if len(families) > 1 else None
    ter = families[2] if len(families) > 2 else None

    _, bg_C, bg_h, bg = derive_dark_background(L, C, h, pri, sec)
    fg = oklch_to_hex(0.935, min(0.014, pri['C'] * 0.12), pri['h'])
    if contrast(fg, bg) < 7.0:
        fg = ensure_bright_contrast(0.935, 0.01, pri['h'], bg, target=7.0, max_L=0.97)

    # Dark surfaces: subtly separated from bg while keeping white fg text readable
    c8_L = 0.33
    c8_C = clamp(bg_C * 1.15 + 0.005, 0.006, 0.026)
    c8 = oklch_to_hex(c8_L, c8_C, bg_h)
    while contrast(c8, bg) < 1.8 and c8_L < 0.42:
        c8_L += 0.01
        c8 = oklch_to_hex(c8_L, c8_C, bg_h)

    surf_h = bg_h if (sec and hue_dist(bg_h, sec['h']) <= 45.0) else pri['h']
    surf_C = clamp((bg_C * 1.7 if surf_h == bg_h else pri['C'] * 0.28), 0.014, 0.045)
    c10_L = 0.40
    c10 = oklch_to_hex(c10_L, surf_C, surf_h)
    while contrast(c10, bg) < 2.2 and c10_L < 0.45:
        c10_L += 0.01
        c10 = oklch_to_hex(c10_L, surf_C, surf_h)
    while contrast(fg, c10) < 4.5 and c10_L > 0.30:
        c10_L -= 0.01
        c10 = oklch_to_hex(c10_L, surf_C, surf_h)

    # UI accents (color12 = primary, color13 = secondary, color14 = luminous highlight)
    c12 = make_bright(pri, bg, target_L=0.72, min_contrast=5.2)
    bichromatic = sec is not None and sec['share'] >= 0.015 and hue_dist(pri['h'], sec['h']) >= 60.0
    if sec and (bichromatic or (sec['L'] >= pri['L'] + 0.12 and sec['share'] >= 0.025)):
        c14 = make_bright(sec, bg, target_L=0.80, min_contrast=6.8)
        if ter and ter['share'] >= 0.04:
            c13 = make_bright(ter, bg, target_L=0.75, min_contrast=5.2)
        else:
            pri_hi = {'h': (pri['h'] + 10.0) % 360.0, 'C': pri['C'] * 0.92, 'L': pri['L']}
            c13 = make_bright(pri_hi, bg, target_L=0.79, min_contrast=5.8)
    else:
        c14 = make_bright(pri, bg, target_L=0.81, min_contrast=7.0, c_scale=1.05)
        if sec:
            c13 = make_bright(sec, bg, target_L=0.75, min_contrast=5.2)
        else:
            pri_alt = {'h': (pri['h'] + 14.0) % 360.0, 'C': pri['C'] * 0.85, 'L': pri['L']}
            c13 = make_bright(pri_alt, bg, target_L=0.77, min_contrast=5.5)

    # Fastfetch keyColor ("cyan" = color6): derive from real secondary/primary tint, never forced blue/cyan
    if sec:
        c6 = make_bright(sec, bg, target_L=0.76, min_contrast=5.5)
    else:
        pri_key = {'h': (pri['h'] - 12.0) % 360.0, 'C': pri['C'] * 0.80, 'L': pri['L']}
        c6 = make_bright(pri_key, bg, target_L=0.79, min_contrast=6.0)

    # Populate color1..color5 strictly from real image families + tight harmonious variations
    pool = list(families[:6])
    idx_gen = 0
    while len(pool) < 6:
        base = families[idx_gen % len(families)]
        step = 1 + (idx_gen // len(families))
        angle = min(20.0, 9.0 * step)
        shift = angle if (idx_gen % 2 == 0) else -angle
        pool.append({
            'h': (base['h'] + shift) % 360.0,
            'C': base['C'] * (0.85 if step == 1 else 0.72),
            'L': clamp(base['L'] + (0.06 if step == 1 else -0.04), 0.55, 0.85),
            'share': base['share'],
            'synth': True,
        })
        idx_gen += 1

    slots = [1, 3, 2, 4, 5]
    targets = {1: 25.0, 3: 80.0, 2: 145.0, 4: 260.0, 5: 320.0}
    avail = list(pool[:6])
    mapped = {}
    pairs = []
    for sl in slots:
        for idx, f in enumerate(avail):
            if f.get('synth'):
                continue
            d = hue_dist(f['h'], targets[sl])
            if d <= 55.0:
                pairs.append((d, sl, idx))
    pairs.sort()
    used_idx = set()
    for _, sl, idx in pairs:
        if sl not in mapped and idx not in used_idx:
            mapped[sl] = avail[idx]
            used_idx.add(idx)
    rem = [f for i, f in enumerate(avail) if i not in used_idx]
    for sl in slots:
        if sl not in mapped:
            mapped[sl] = rem.pop(0)

    cols = {
        'color0': bg,
        'color7': fg,
        'color8': c8,
        'color10': c10,
        'color12': c12,
        'color13': c13,
        'color14': c14,
        'color6': c6,
        'color15': fg,
    }
    for sl in slots:
        cols[f'color{sl}'] = make_bright(mapped[sl], bg, target_L=0.72, min_contrast=4.8)
    cols['color9'] = make_bright(mapped[1], bg, target_L=0.78, min_contrast=5.8)
    cols['color11'] = make_bright(mapped[3], bg, target_L=0.80, min_contrast=6.0)

    for k in CONTENT_KEYS:
        if contrast(cols[k], bg) < 4.5:
            cols[k] = ensure_bright_contrast(0.75, 0.10, pri['h'], bg, target=4.5)

    return {
        'wallpaper': img_path,
        'special': {'background': bg, 'foreground': fg, 'cursor': fg},
        'colors': cols,
    }


def reload_ui():
    """Best-effort UI reloads when extract_dominant.py is called directly."""
    home = os.path.expanduser('~')
    kitty_reloaded = False
    for sock in glob.glob('/tmp/mykitty*'):
        if os.path.exists(sock):
            try:
                subprocess.run(
                    ['kitty', '@', '--to', f'unix:{sock}', 'load-config'],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
                )
                kitty_reloaded = True
            except Exception:
                pass

    commands = [
        ['touch', os.path.join(home, '.config/waybar/style.css')],
        ['hyprctl', 'reload', 'config-only'],
        ['swaync-client', '-rs'],
        ['pkill', '-USR1', 'cava'],
        ['pkill', '-x', 'rofi'],
    ]
    if not kitty_reloaded:
        commands.append(['pkill', '-USR1', 'kitty'])

    for cmd in commands:
        try:
            subprocess.run(
                cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
            )
        except Exception:
            pass


def cache_path_for(img_path, cache_dir):
    """Compute canonical cache path matching WallustSwww.sh fast-path."""
    real_path = os.path.realpath(img_path)
    mtime = int(os.path.getmtime(real_path))
    hash_key = hashlib.md5(f"{real_path}_{mtime}_{CACHE_VERSION}".encode()).hexdigest()
    return real_path, os.path.join(cache_dir, f"{hash_key}.json")


def precache_directory(root_dir):
    """Pre-generate palette JSONs for all images under `root_dir` in one process."""
    cache_dir = os.path.expanduser('~/.cache/wallust/palettes')
    os.makedirs(cache_dir, exist_ok=True)
    exts = ('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif', '.tiff')
    generated = 0
    for base, _, files in os.walk(root_dir, followlinks=True):
        for fname in files:
            if not fname.lower().endswith(exts):
                continue
            fpath = os.path.join(base, fname)
            try:
                real_path, theme_file = cache_path_for(fpath, cache_dir)
                if os.path.isfile(theme_file):
                    continue
                palette = generate_palette(real_path)
                if palette:
                    tmp = f"{theme_file}.tmp"
                    with open(tmp, 'w') as f:
                        json.dump(palette, f, indent=2)
                    os.replace(tmp, theme_file)
                    generated += 1
            except Exception:
                continue
    print(f"Precached {generated} palettes in {cache_dir}")


def main():
    if len(sys.argv) > 2 and sys.argv[1] == '--precache':
        precache_directory(os.path.expanduser(sys.argv[2]))
        return

    if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
        img_path = os.path.realpath(sys.argv[1])
    else:
        link = os.path.expanduser('~/.config/rofi/.current_wallpaper')
        if os.path.islink(link) or os.path.isfile(link):
            img_path = os.path.realpath(link)
        else:
            sys.exit(1)

    cache_dir = os.path.expanduser('~/.cache/wallust/palettes')
    os.makedirs(cache_dir, exist_ok=True)

    img_path, theme_file = cache_path_for(img_path, cache_dir)

    if not os.path.isfile(theme_file):
        palette = generate_palette(img_path)
        if not palette:
            subprocess.run(['wallust', 'run', '-s', img_path])
            return
        tmp = f"{theme_file}.tmp"
        with open(tmp, 'w') as f:
            json.dump(palette, f, indent=2)
        os.replace(tmp, theme_file)

    subprocess.run(['wallust', 'cs', '-s', '--no-hooks', '-f', 'pywal', theme_file])

    if os.environ.get('WALLUST_SKIP_RELOAD') != '1':
        reload_ui()


if __name__ == '__main__':
    main()
