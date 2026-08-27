#!/usr/bin/env python3
"""The widget contact sheet, from the tiles the platform itself drew.

The 35 square tiles in docs/images/widgets.png are not drawn by anything in
this repo — they come out of `WidgetRenderTests`, which renders the real
SwiftUI views the extension ships. This only lays them out.

    xcodebuild test -project ios/Runner.xcodeproj -scheme Runner \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -only-testing:RunnerTests/WidgetRenderTests \
      -parallel-testing-enabled NO

That prints `WIDGET TILES: <dir>`. Hand the directory over:

    python3 tool/brand/widgets.py <dir>

Every tile arrives with transparent corners — `ImageRenderer` clips each one
to a rounded rectangle — so they are composited onto the page's own cream
rather than flattened onto whatever the alpha happens to fall on. Doing that
by hand once left four black wedges on all 35, which is the reason this file
exists.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'docs', 'images', 'widgets.png')
CREAM = (245, 234, 216)

# Conditions down the page, skies across it — the order both enums declare.
CONDITIONS = ['clear', 'cloudy', 'fog', 'drizzle', 'rain', 'snow', 'storm']
SKIES = ['dawn', 'morning', 'afternoon', 'evening', 'night']

CELL = 163   # a 200pt tile, rendered at 2x, shown small enough for 35 to fit
GAP = 2
MARGIN = 22


def sheet(tiles):
    width = MARGIN * 2 + len(SKIES) * CELL + (len(SKIES) - 1) * GAP
    height = MARGIN * 2 + len(CONDITIONS) * CELL + (len(CONDITIONS) - 1) * GAP
    page = Image.new('RGB', (width, height), CREAM)

    for row, condition in enumerate(CONDITIONS):
        for col, sky in enumerate(SKIES):
            name = f'square-{condition}-{sky}.png'
            path = os.path.join(tiles, name)
            if not os.path.exists(path):
                sys.exit(f'missing tile: {path}')
            tile = Image.open(path).convert('RGBA')
            if tile.width != tile.height:
                sys.exit(f'{name} is {tile.width}x{tile.height}, expected a square')
            tile = tile.resize((CELL, CELL), Image.LANCZOS)
            page.paste(tile, (MARGIN + col * (CELL + GAP),
                              MARGIN + row * (CELL + GAP)), tile)

    page.save(OUT)
    print(f'{os.path.relpath(OUT, ROOT)}  {width}x{height}')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(f'usage: {os.path.basename(sys.argv[0])} <tile-directory>')
    sheet(sys.argv[1])
