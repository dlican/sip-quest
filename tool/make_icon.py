"""Generates the Party Party launcher icons from a hand-drawn pixel die.

Run from the repo root:  python tool/make_icon.py   (needs Pillow)
"""
import json
import os
from PIL import Image, ImageDraw

BG = (13, 2, 33)          # Neon Arcade background
GLOW = (255, 42, 109)     # Neon pink
COLORS = {
    'W': (255, 248, 231),  # die face
    'P': (255, 42, 109),   # neon pink pips
    'K': (150, 140, 200),  # face edge
    'C': (5, 217, 232),    # cyan side
}
DIE = [
    ".KKKKKKKKKK...",
    "KWWWWWWWWWWK..",
    "KWPPWWWWPPWKC.",
    "KWPPWWWWPPWKCC",
    "KWWWWWWWWWWKCC",
    "KWWWWPPWWWWKCC",
    "KWWWWPPWWWWKCC",
    "KWWWWWWWWWWKCC",
    "KWPPWWWWPPWKCC",
    "KWPPWWWWPPWKCC",
    "KWWWWWWWWWWKCC",
    ".KKKKKKKKKKCCC",
    "..CCCCCCCCCCCC",
    "...CCCCCCCCCC.",
]


def die_layer(grid, scale_px, offset):
    """Draws the die onto a transparent grid-sized image (1 cell = 1 px)."""
    img = Image.new('RGBA', (grid, grid), (0, 0, 0, 0))
    ox, oy = offset
    for y, row in enumerate(DIE):
        for x, ch in enumerate(row):
            if ch in COLORS:
                img.putpixel((ox + x, oy + y), COLORS[ch] + (255,))
    return img


def centered(grid):
    w, h = len(DIE[0]), len(DIE)
    return die_layer(grid, 1, ((grid - w) // 2, (grid - h) // 2))


def full_icon(size, rounded=True):
    """Legacy/iOS/web icon: dark tile with a neon border and the die."""
    grid = 21
    tile = Image.new('RGBA', (grid, grid), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    if rounded:
        d.rectangle([1, 0, grid - 2, grid - 1], fill=BG + (255,))
        d.rectangle([0, 1, grid - 1, grid - 2], fill=BG + (255,))
        # Pixel-stepped neon frame.
        d.line([2, 1, grid - 3, 1], fill=GLOW + (255,))
        d.line([2, grid - 2, grid - 3, grid - 2], fill=GLOW + (255,))
        d.line([1, 2, 1, grid - 3], fill=GLOW + (255,))
        d.line([grid - 2, 2, grid - 2, grid - 3], fill=GLOW + (255,))
    else:
        d.rectangle([0, 0, grid - 1, grid - 1], fill=BG + (255,))
    tile.alpha_composite(centered(grid))
    out = tile.resize((size, size), Image.NEAREST)
    return out if rounded else out.convert('RGB')


def foreground(size):
    """Adaptive icon foreground: die inside the 66/108 safe zone."""
    grid = 27
    return centered(grid).resize((size, size), Image.NEAREST)


def main():
    res = 'android/app/src/main/res'
    legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for dpi, px in legacy.items():
        d = f'{res}/mipmap-{dpi}'
        os.makedirs(d, exist_ok=True)
        full_icon(px).save(f'{d}/ic_launcher.png')
        foreground(px * 108 // 48).save(f'{d}/ic_launcher_foreground.png')

    os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
    with open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    with open(f'{res}/values/ic_launcher_background.xml', 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                '    <color name="ic_launcher_background">#0D0221</color>\n</resources>\n')

    # iOS: opaque, full-bleed (iOS rounds the corners itself).
    ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    if os.path.isdir(ios):
        for name in os.listdir(ios):
            if name.endswith('.png'):
                with Image.open(f'{ios}/{name}') as old:
                    px = old.size[0]
                full_icon(px, rounded=False).save(f'{ios}/{name}')

    # Web favicon and PWA icons.
    for path in ['web/favicon.png'] + [f'web/icons/{n}' for n in
                                        (os.listdir('web/icons') if os.path.isdir('web/icons') else [])]:
        if path.endswith('.png') and os.path.exists(path):
            with Image.open(path) as old:
                px = old.size[0]
            if 'maskable' in path:
                tile = Image.new('RGB', (px, px), BG)
                fg = foreground(px)
                tile.paste(fg, (0, 0), fg)
                tile.save(path)
            else:
                full_icon(px).save(path)

    full_icon(512).save('tool/icon_preview.png')


if __name__ == '__main__':
    main()
