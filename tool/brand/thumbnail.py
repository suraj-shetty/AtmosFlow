#!/usr/bin/env python3
"""The portfolio thumbnail — 4:3, and legible at the size it is shown.

A gallery card is looked at for about a second, at a couple of hundred pixels
across. So this is built for that size rather than for the size of the file:
three phones large enough to read as weather at a glance, one line of type big
enough to survive the downscale, and two widget tiles to say the part that
Flutter alone does not.

Everything in it is already in the repo. The phones are golden files — the
same images the test suite compares every build against — so the card cannot
show the app looking like anything the tests do not.

    python3 tool/brand/thumbnail.py
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gallery  # noqa: E402

ROOT = gallery.ROOT
OUT = os.path.join(ROOT, 'docs', 'images', 'upwork-thumbnail.png')
FONTS = os.path.join(ROOT, 'assets', 'fonts')
CREAM = gallery.CREAM
INK = (32, 30, 29)

WIDTH, HEIGHT = 1200, 900

# Three that separate tonally, so the fan still reads as three skies once the
# card is 250px wide: light, dark, mid. Their mean values are 243, 63 and 172.
PHONES = ['home_clear_day.png', 'home_storm_night.png', 'home_rain_day.png']

# Two tiles out of the contact sheet, by their cell in the 5-across grid.
TILES = [('clear', 'afternoon'), ('storm', 'night'), ('rain', 'morning')]
CONDITIONS = ['clear', 'cloudy', 'fog', 'drizzle', 'rain', 'snow', 'storm']
SKIES = ['dawn', 'morning', 'afternoon', 'evening', 'night']
SHEET_MARGIN, SHEET_CELL, SHEET_GAP = 22, 163, 2


def tile(condition, sky, size):
    """One widget tile, lifted back out of the contact sheet."""
    sheet = Image.open(os.path.join(ROOT, 'docs', 'images', 'widgets.png')).convert('RGB')
    col, row = SKIES.index(sky), CONDITIONS.index(condition)
    x = SHEET_MARGIN + col * (SHEET_CELL + SHEET_GAP)
    y = SHEET_MARGIN + row * (SHEET_CELL + SHEET_GAP)
    return sheet.crop((x, y, x + SHEET_CELL, y + SHEET_CELL)).resize(
        (size, size), Image.LANCZOS)


def build():
    card = Image.new('RGB', (WIDTH, HEIGHT), CREAM)

    # ── The phones, fanned right of the type. Drawn back to front so each
    # shadow falls on the one behind it, and the first one read is in front.
    height = 660
    step = 168
    cards = [gallery._phone(name, height) for name in PHONES]
    span = cards[0].width + step * (len(cards) - 1)
    x0 = WIDTH - 26 - span
    top = (HEIGHT - cards[0].height) // 2
    for index in reversed(range(len(cards))):
        phone = cards[index]
        card.paste(phone, (x0 + index * step, top + index * 16), phone)

    draw = ImageDraw.Draw(card)
    left = 62
    room = x0 - left - 4

    # The wordmark is set to the width it has rather than to a fixed size —
    # it is the one element that has to survive the downscale.
    size = 96
    while size > 40:
        wordmark = ImageFont.truetype(os.path.join(FONTS, 'Caprasimo-Regular.ttf'), size)
        if draw.textlength('AtmosFlow', font=wordmark) <= room:
            break
        size -= 2

    line = ImageFont.truetype(os.path.join(FONTS, 'Figtree-SemiBold.ttf'), 30)
    small = ImageFont.truetype(os.path.join(FONTS, 'Figtree-Regular.ttf'), 25)
    tile_size = 126

    # Lay the column out as one block and centre it, so the card stays
    # balanced whatever the wordmark ended up being set at.
    block = [
        ('AtmosFlow', wordmark, INK, 10, 34),
        ('Designed and built\nend to end', line, INK, 10, 26),
        ('Flutter · native widgets\non iOS and Android', small, (92, 84, 76), 10, 38),
    ]
    heights = [draw.multiline_textbbox((0, 0), text, font=font, spacing=gap)[3]
               for text, font, _, gap, _ in block]
    total = sum(heights) + sum(after for *_, after in block) + tile_size
    y = (HEIGHT - total) // 2

    for (text, font, fill, gap, after), height in zip(block, heights):
        draw.multiline_text((left, y), text, font=font, fill=fill, spacing=gap)
        y += height + after

    # ── The tiles, to say the part Flutter alone does not.
    for index, (condition, sky) in enumerate(TILES):
        card.paste(tile(condition, sky, tile_size),
                   (left + index * (tile_size + 14), y))

    card.save(OUT)
    print(f'{os.path.relpath(OUT, ROOT)}  {WIDTH}x{HEIGHT}')


if __name__ == '__main__':
    build()
