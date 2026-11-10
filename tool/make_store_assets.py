"""Generates the Google Play store icon (512x512) and feature graphic (1024x500).

Run from the repo root:  python tool/make_store_assets.py   (needs Pillow)
Output goes to docs/store/. Uses the same pixel die as tool/make_icon.py.
"""
import os
import random
from PIL import Image, ImageDraw

from make_icon import BG, COLORS, GLOW, DIE

CYAN = (5, 217, 232)
PURPLE = (60, 20, 110)

# 5x7 pixel font, only the letters we need.
FONT = {
    'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    'D': ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    'E': ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    'F': ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    'G': ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
    'I': ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    'M': ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    'Q': ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    'R': ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    ' ': ["00000"] * 7,
    '-': ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
}


def text_width(text, cell):
    return (len(text) * 6 - 1) * cell


def draw_text(d, text, x, y, cell, color):
    for ch in text:
        for ry, row in enumerate(FONT[ch]):
            for rx, bit in enumerate(row):
                if bit == '1':
                    d.rectangle([x + rx * cell, y + ry * cell,
                                 x + (rx + 1) * cell - 1, y + (ry + 1) * cell - 1], fill=color)
        x += 6 * cell


def draw_die(d, x, y, cell):
    for ry, row in enumerate(DIE):
        for rx, ch in enumerate(row):
            if ch in COLORS:
                d.rectangle([x + rx * cell, y + ry * cell,
                             x + (rx + 1) * cell - 1, y + (ry + 1) * cell - 1], fill=COLORS[ch])


def sparkles(d, w, h, cell, count, seed, avoid):
    rnd = random.Random(seed)
    for _ in range(count):
        x = rnd.randrange(0, w // cell) * cell
        y = rnd.randrange(0, h // cell) * cell
        if any(a[0] - cell <= x <= a[2] and a[1] - cell <= y <= a[3] for a in avoid):
            continue
        color = rnd.choice([GLOW, CYAN, (249, 200, 14), PURPLE, PURPLE])
        d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=color)


def play_icon():
    """512x512, full-bleed square. Play rounds the corners itself."""
    size, cell = 512, 24
    img = Image.new('RGB', (size, size), BG)
    d = ImageDraw.Draw(img)
    mw, mh = len(DIE[0]) * cell, len(DIE) * cell
    mx, my = (size - mw) // 2, (size - mh) // 2
    draw_die(d, mx, my, cell)
    return img


def feature_graphic():
    w, h = 1024, 500
    img = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(img)

    # Pixel-stepped neon frame.
    f = 8
    d.rectangle([2 * f, f, w - 2 * f - 1, 2 * f - 1], fill=GLOW)
    d.rectangle([2 * f, h - 2 * f, w - 2 * f - 1, h - f - 1], fill=GLOW)
    d.rectangle([f, 2 * f, 2 * f - 1, h - 2 * f - 1], fill=GLOW)
    d.rectangle([w - 2 * f, 2 * f, w - f - 1, h - 2 * f - 1], fill=GLOW)

    die_cell = 14
    mw, mh = len(DIE[0]) * die_cell, len(DIE) * die_cell
    title, title_cell = "PARTY PARTY", 8
    tag, tag_cell = "PIXEL PARTY GAMES", 5
    gap = 56
    total = mw + gap + text_width(title, title_cell)
    mx, my = (w - total) // 2, (h - mh) // 2
    tx = mx + mw + gap
    block_h = 7 * title_cell + 36 + 7 * tag_cell
    ty = (h - block_h) // 2
    tag_y = ty + 7 * title_cell + 36

    avoid = [(mx - 20, my - 20, mx + mw + 20, my + mh + 20),
             (tx - 20, ty - 20, tx + text_width(title, title_cell) + 20, tag_y + 7 * tag_cell + 20)]
    sparkles(d, w, h, 8, 70, 7, avoid + [(0, 0, w, 3 * f), (0, h - 3 * f, w, h),
                                      (0, 0, 3 * f, h), (w - 3 * f, 0, w, h)])

    draw_die(d, mx, my, die_cell)
    # Cyan drop shadow, then pink title.
    draw_text(d, title, tx + title_cell // 2 + 2, ty + title_cell // 2 + 2, title_cell, CYAN)
    draw_text(d, title, tx, ty, title_cell, GLOW)
    tag_x = tx + (text_width(title, title_cell) - text_width(tag, tag_cell)) // 2
    draw_text(d, tag, tag_x, tag_y, tag_cell, COLORS['W'])
    return img


def main():
    out = 'docs/store'
    os.makedirs(out, exist_ok=True)
    play_icon().save(f'{out}/play-icon-512.png')
    feature_graphic().save(f'{out}/feature-graphic-1024x500.png')


if __name__ == '__main__':
    main()
