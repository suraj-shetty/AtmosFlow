#!/usr/bin/env python3
"""Rasterise the AtmosFlow mark into every slot the two platforms want.

The design is CSS, so the rasteriser is a browser: mark.py emits the design's
own declarations and Chrome draws them. Rendered at 248px against the brand
file's markup, the output is pixel-identical.

    python3 tool/brand/render.py

Idempotent — it overwrites what it owns and touches nothing else.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mark  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
IOS = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
CHROME = ('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')

# Android's density buckets, as multiples of the baseline.
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def shoot(html, width, height, out):
    """One page, one PNG, at exactly the size asked for."""
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False) as f:
        f.write(html)
        page = f.name
    try:
        subprocess.run(
            [CHROME, '--headless', '--disable-gpu', '--no-sandbox',
             '--hide-scrollbars', '--default-background-color=00000000',
             '--force-device-scale-factor=1',
             f'--window-size={width},{height}',
             f'--screenshot={out}', f'file://{page}'],
            check=True, capture_output=True,
        )
    finally:
        os.unlink(page)
    if not os.path.exists(out):
        raise SystemExit(f'chrome wrote nothing for {out}')
    print('  ', os.path.relpath(out, ROOT))


def square(html, size, out):
    shoot(html, size, size, out)


# ── iOS app icon ──────────────────────────────────────────────────────────
def ios_icon():
    """Every size in the app icon set, each drawn for the size it is seen at.

    A 20pt icon is a 20pt icon whether the screen draws it with 20 pixels or
    60, so the tier follows the point size and the raster follows the scale.
    """
    print('iOS app icon')
    catalog = os.path.join(IOS, 'AppIcon.appiconset')
    seen = {}
    for image in json.load(open(os.path.join(catalog, 'Contents.json')))['images']:
        pt = float(image['size'].split('x')[0])
        px = round(pt * float(image['scale'].rstrip('x')))
        seen[image['filename']] = (pt, px)
    for name, (pt, px) in sorted(seen.items()):
        square(mark.icon(px, mark.tier_for(pt)), px,
               os.path.join(catalog, name))


# ── Android launcher icon ─────────────────────────────────────────────────
def android_icon():
    """Adaptive layers, plus a flat square for the two API levels below 26.

    Android gets the full mark at every size: the design's own circle and
    squircle swatches are drawn that way, and they are what a launcher shows.
    """
    print('Android launcher icon')
    for bucket, scale in DENSITIES.items():
        legacy = round(48 * scale)
        square(mark.icon(legacy, mark.FULL), legacy,
               os.path.join(RES, f'mipmap-{bucket}', 'ic_launcher.png'))

        canvas = round(108 * scale)
        square(mark.sky(canvas, canvas, mark.DAWN), canvas,
               os.path.join(RES, f'drawable-{bucket}', 'ic_launcher_background.png'))
        square(mark.icon(canvas, mark.FULL, sky=False, inner=2 / 3), canvas,
               os.path.join(RES, f'drawable-{bucket}', 'ic_launcher_foreground.png'))
        square(mark.icon(canvas, mark.FULL, sky=False, inner=2 / 3, mono=True),
               canvas,
               os.path.join(RES, f'drawable-{bucket}', 'ic_launcher_monochrome.png'))


# ── Launch screen ─────────────────────────────────────────────────────────
# The launch image is one flat sky with the mark at rest on it — no text, no
# motion. Everything that moves belongs to the Flutter splash that follows.
LAUNCH_W, LAUNCH_H = 440, 956  # the largest iPhone's logical screen
TILE_PT = 78                   # the mark, as the design draws it on the splash
TILE_PAD = 0.5                 # room for the drop shadow


def ios_launch():
    print('iOS launch screen')
    tile_canvas = round(TILE_PT * (1 + 2 * TILE_PAD))
    for night in (False, True):
        suffix = '-dark' if night else ''
        for scale in (1, 2, 3):
            at = '' if scale == 1 else f'@{scale}x'
            shoot(mark.sky(LAUNCH_W * scale, LAUNCH_H * scale,
                           mark.SPLASH_NIGHT if night else mark.SPLASH),
                  LAUNCH_W * scale, LAUNCH_H * scale,
                  os.path.join(IOS, 'LaunchBackground.imageset',
                               f'LaunchBackground{suffix}{at}.png'))
            html, canvas = mark.tile(TILE_PT * scale, night=night, pad=TILE_PAD)
            square(html, canvas,
                   os.path.join(IOS, 'LaunchMark.imageset',
                                f'LaunchMark{suffix}{at}.png'))

    def contents(stem):
        images = []
        for night in (False, True):
            suffix = '-dark' if night else ''
            for scale in (1, 2, 3):
                at = '' if scale == 1 else f'@{scale}x'
                entry = {
                    'idiom': 'universal',
                    'filename': f'{stem}{suffix}{at}.png',
                    'scale': f'{scale}x',
                }
                if night:
                    entry['appearances'] = [
                        {'appearance': 'luminosity', 'value': 'dark'}
                    ]
                images.append(entry)
        return {'images': images, 'info': {'version': 1, 'author': 'atmosflow'}}

    for stem in ('LaunchBackground', 'LaunchMark'):
        path = os.path.join(IOS, f'{stem}.imageset', 'Contents.json')
        with open(path, 'w') as f:
            json.dump(contents(stem), f, indent=2)
            f.write('\n')
        print('  ', os.path.relpath(path, ROOT))
    print('  (mark canvas is', tile_canvas, 'pt — the tile is 78pt inside it)')

    stale = os.path.join(IOS, 'LaunchImage.imageset')
    if os.path.isdir(stale):
        shutil.rmtree(stale)
        print('   removed LaunchImage.imageset')


def android_launch():
    """The gradient stretches, so it ships once; the mark does not, so it
    ships per density."""
    print('Android launch screen')
    for night in (False, True):
        folder = 'drawable-night-nodpi' if night else 'drawable-nodpi'
        shoot(mark.sky(LAUNCH_W, LAUNCH_H, mark.SPLASH_NIGHT if night else mark.SPLASH),
              LAUNCH_W, LAUNCH_H,
              os.path.join(RES, folder, 'launch_gradient.png'))
        for bucket, scale in DENSITIES.items():
            html, canvas = mark.tile(TILE_PT * scale, night=night, pad=TILE_PAD)
            suffix = '-night' if night else ''
            square(html, canvas,
                   os.path.join(RES, f'drawable{suffix}-{bucket}',
                                'launch_mark.png'))


if __name__ == '__main__':
    ios_icon()
    android_icon()
    ios_launch()
    android_launch()
    print('done')
