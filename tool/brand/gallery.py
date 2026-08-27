#!/usr/bin/env python3
"""The README's pictures, built from what the repo already holds.

The banner is drawn the same way everything else brand-related is — the
design's own CSS, rendered by Chrome, in the app's own faces. The screen
strips are the golden files: the README therefore cannot show the app looking
like anything other than what the tests say it looks like.

    python3 tool/brand/gallery.py
"""
import os
import sys

from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mark  # noqa: E402
import render  # noqa: E402

ROOT = render.ROOT
OUT = os.path.join(ROOT, 'docs', 'images')
GOLDENS = os.path.join(ROOT, 'test', 'goldens')
CREAM = (245, 234, 216)


def banner(width=1240, height=380):
    """The mark and the wordmark on the splash's own sky."""
    fonts = os.path.join(ROOT, 'assets', 'fonts')
    tile = 132
    body = f'''
    <style>
      @font-face {{ font-family: Caprasimo;
        src: url("file://{fonts}/Caprasimo-Regular.ttf"); }}
      @font-face {{ font-family: Figtree; font-weight: 400;
        src: url("file://{fonts}/Figtree-Regular.ttf"); }}
    </style>
    <div style="position:absolute;inset:0;background:{mark.SPLASH}"></div>
    <div style="position:absolute;left:50%;top:44%;width:620px;height:620px;
                margin:-310px 0 0 -310px;border-radius:999px;
                background:radial-gradient(circle,rgba(255,238,190,.55),
                transparent 66%)"></div>
    <div style="position:absolute;inset:0;display:flex;align-items:center;
                justify-content:center;gap:34px">
      <div style="width:{tile}px;height:{tile}px;border-radius:{tile * 0.282:.0f}px;
                  background:{mark.TILE_DAWN};position:relative;overflow:hidden;
                  box-shadow:0 14px 40px rgba(32,30,29,.22);flex:none">
        {mark._mark(mark.TILE, tile)}
      </div>
      <div style="display:flex;flex-direction:column;gap:10px">
        <div style="font-family:Caprasimo;font-size:66px;line-height:1;
                    letter-spacing:-.01em;color:#201e1d">AtmosFlow</div>
        <div style="font-family:Figtree;font-size:21px;line-height:1;
                    letter-spacing:.02em;color:rgba(32,30,29,.66)">
          Your sky, beautifully forecasted</div>
      </div>
    </div>'''
    render.shoot(mark._page(body, width, height), width, height,
                 os.path.join(OUT, 'banner.png'))


def _phone(name, height):
    """One golden, rounded off and given a little ground to stand on."""
    im = Image.open(os.path.join(GOLDENS, name)).convert('RGB')
    scale = height / im.height
    im = im.resize((round(im.width * scale), height), Image.LANCZOS)

    radius = round(46 * scale)
    mask = Image.new('L', im.size, 0)
    from PIL import ImageDraw
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.width - 1, im.height - 1],
                                           radius=radius, fill=255)
    pad = round(height * 0.055)
    card = Image.new('RGBA', (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))

    shadow = Image.new('RGBA', card.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [pad, pad + round(pad * 0.35), pad + im.width, pad + im.height + round(pad * 0.35)],
        radius=radius, fill=(32, 30, 29, 64))
    shadow = shadow.filter(ImageFilter.GaussianBlur(pad * 0.45))
    card.alpha_composite(shadow)
    card.paste(im, (pad, pad), mask)
    return card


def strip(names, out, height=560, background=CREAM):
    cards = [_phone(n, height) for n in names]
    w = sum(c.width for c in cards)
    sheet = Image.new('RGB', (w, cards[0].height), background)
    x = 0
    for c in cards:
        sheet.paste(c, (x, 0), c)
        x += c.width
    sheet.save(os.path.join(OUT, out))
    print('  ', os.path.relpath(os.path.join(OUT, out), ROOT))


def grid(rows, out, height=300, background=CREAM):
    cards = [[_phone(n, height) for n in row] for row in rows]
    w = max(sum(c.width for c in row) for row in cards)
    h = sum(row[0].height for row in cards)
    sheet = Image.new('RGB', (w, h), background)
    y = 0
    for row in cards:
        x = 0
        for c in row:
            sheet.paste(c, (x, y), c)
            x += c.width
        y += row[0].height
    sheet.save(os.path.join(OUT, out))
    print('  ', os.path.relpath(os.path.join(OUT, out), ROOT))


CONDITIONS = ['clear', 'cloudy', 'fog', 'drizzle', 'rain', 'snow', 'storm']

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    print('README images')
    banner()
    strip(['splash-day.png', 'home_clear_day.png', 'day_detail.png',
           'search.png', 'settings.png'], 'screens.png')
    grid([[f'home_{c}_day.png' for c in CONDITIONS],
          [f'home_{c}_night.png' for c in CONDITIONS]], 'skies.png')
    # docs/images/widgets.png is not rebuilt here: the widget tiles are drawn
    # by the platforms themselves, so they need a simulator running first.
    # tool/brand/widgets.py lays them out once the harness has written them.
    print('done')
