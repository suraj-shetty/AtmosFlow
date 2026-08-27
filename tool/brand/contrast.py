#!/usr/bin/env python3
"""What each string on a widget tile actually reads at.

The widget design carries two sets of copy colours and picks between them by
sky. The copy is not drawn on the sky, though — it is drawn on the sky with
the condition's veil over it, and four of the seven veils move a tile far
enough to change which set should win. This is how that was found, and how to
check it again when a veil or a colour moves.

`WidgetRenderTests` writes two directories: the finished tiles, and the same
tiles with no copy on them. Both are needed. Contrast cannot be read off a
finished tile alone, because the pixels a string covers *are* the string —
the ground underneath has to come from somewhere else, and diffing the two
says exactly which pixels the copy reached.

    xcodebuild test -project ios/Runner.xcodeproj -scheme Runner \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -only-testing:RunnerTests/WidgetRenderTests \
      -parallel-testing-enabled NO

    python3 tool/brand/contrast.py <tiles dir> <backgrounds dir>

Each row prints both sets, so a tile where the unused set is the higher
number is a tile drawing its copy in the wrong one. A star marks those.

Three caveats on reading the output. The numbers are WCAG contrast ratios,
which want 4.5 for body copy and 3.0 for large; several tiles sit under that in
whichever set wins, and closing those means moving the design's colours rather
than choosing between them. `clear|night` scores its glyph at 2.5 without
anything being wrong — the crescent is drawn over the ambient moon on purpose.
And a star is not always an argument: `fog|night` would gain 0.6 on the
temperature in ink and lose more than that on the caption and the footer, which
is why it stays white.
"""
import os
import sys

from PIL import Image

CONDITIONS = ['clear', 'cloudy', 'fog', 'drizzle', 'rain', 'snow', 'storm']
SKIES = ['dawn', 'morning', 'afternoon', 'evening', 'night']

WHITE = (255, 255, 255)
INK = (0x1b, 0x1f, 0x26)
INK_SOFT = (40, 46, 56)

# Where each string lands on the 200pt square tile, rendered at 2x, and the
# colour it is drawn in on a dark tile and on a light one. The bands are the
# rows the diff finds copy in; the x test separates what shares a band.
ELEMENTS = [
    ('temp',    (43, 111),  lambda x: x < 220,  (WHITE, 1.00), (INK, 1.00)),
    ('glyph',   (43, 111),  lambda x: x >= 240, (WHITE, 1.00), (INK, 1.00)),
    ('caption', (140, 175), lambda x: True,     (WHITE, 0.82), (INK_SOFT, 0.78)),
    ('droplet', (340, 368), lambda x: x < 64,   (WHITE, 0.68), (INK_SOFT, 0.68)),
    ('footer',  (340, 368), lambda x: x >= 64,  (WHITE, 0.86), (INK_SOFT, 0.62)),
]

# The rule WidgetPalette applies, restated here so the table can disagree
# with it. Keep the two in step.
DUSK = ('dawn', 'evening')
DARKENS = ('rain', 'storm')
LIGHTENS = ('fog', 'snow')


def takes_white(condition, sky):
    if sky == 'night':
        return True
    if sky in DUSK:
        return condition not in LIGHTENS
    return condition in DARKENS


def luminance(c):
    def channel(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * channel(c[0]) + 0.7152 * channel(c[1]) + 0.0722 * channel(c[2])


def ratio(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def over(colour, opacity, ground):
    return tuple(colour[i] * opacity + ground[i] * (1 - opacity) for i in range(3))


def measure(tile, background):
    """Every element's ratio in both sets, against its own patch of ground."""
    a, b = tile.load(), background.load()
    out = {}
    for name, (top, bottom), keep, on_dark, on_light in ELEMENTS:
        ground = [b[x, y]
                  for y in range(top, bottom)
                  for x in range(tile.width)
                  if keep(x) and max(abs(a[x, y][i] - b[x, y][i]) for i in range(3)) > 12]
        if not ground:
            out[name] = None
            continue
        mean = tuple(sum(p[i] for p in ground) / len(ground) for i in range(3))
        out[name] = (ratio(over(*on_dark, mean), mean),
                     ratio(over(*on_light, mean), mean))
    return out


def report(tiles, backgrounds):
    names = [e[0] for e in ELEMENTS]
    print(f"{'tile':<18}{'set':<7}" + ''.join(f'{n:>16}' for n in names))
    print(f"{'':<25}" + ''.join(f"{'white':>8}{'ink':>8}" for _ in names))

    wrong = []
    for condition in CONDITIONS:
        for sky in SKIES:
            name = f'square-{condition}-{sky}.png'
            tile = os.path.join(tiles, name)
            ground = os.path.join(backgrounds, name)
            for path in (tile, ground):
                if not os.path.exists(path):
                    sys.exit(f'missing: {path}')
            white = takes_white(condition, sky)
            found = measure(Image.open(tile).convert('RGB'),
                            Image.open(ground).convert('RGB'))

            row = ''
            for n in names:
                if found[n] is None:
                    row += f"{'-':>16}"
                    continue
                w, i = found[n]
                chosen, other = (w, i) if white else (i, w)
                mark = '*' if other > chosen + 0.5 else ' '
                row += f'{w:8.2f}{i:7.2f}{mark}'
                if mark == '*' and n in ('temp', 'caption', 'footer'):
                    wrong.append((f'{condition}|{sky}', n, chosen, other))
            print(f"{condition + '|' + sky:<18}{'white' if white else 'ink':<7}{row}")

    print()
    if wrong:
        print('elements the other set would score higher on:')
        for tile, element, chosen, other in wrong:
            print(f'  {tile:<18}{element:<9}{chosen:5.2f} → {other:5.2f}')
    else:
        print('every tile is drawing its copy in the better of the two sets.')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(f'usage: {os.path.basename(sys.argv[0])} <tiles> <backgrounds>')
    report(sys.argv[1], sys.argv[2])
