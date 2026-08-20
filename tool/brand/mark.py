"""The AtmosFlow mark, as the brand design draws it.

Every length here is a fraction of the artwork's own box, read off the
design's CSS at the size it was drawn: the 248px icon master, the 96px and
64px adaptive swatches, the 40px and 20px small sizes, and the 78px launch
tile. Working in fractions is what lets one description serve a 20px
notification badge and a 1024px App Store master.

The output is HTML, not pixels. The design is CSS, so the most faithful
rasteriser is a browser — see render.py.
"""

# ── Palette ───────────────────────────────────────────────────────────────
DAWN = 'linear-gradient(168deg,#8fc4e8 0%,#f2d3ae 58%,#e8a06a 100%)'
# Below 40px the design drops the middle stop; two colours survive scaling
# down better than three.
DAWN_MICRO = 'linear-gradient(168deg,#8fc4e8 0%,#e8a06a 100%)'
NIGHT = 'linear-gradient(168deg,#26304f 0%,#141a30 100%)'

# The launch screen's sky. The design's cold-start mock reuses the icon's own
# gradient, but the frame after it — the one Flutter draws and then animates —
# is this: one more stop and a shallower angle, because a phone screen is a
# far taller box than an icon. Shipping *this* as the launch image is what
# makes the handoff invisible, which is what the whole section is about.
SPLASH = ('linear-gradient(172deg,#7db4e0 0%,#bcd2e6 40%,'
          '#f2d3ae 76%,#e8a06a 100%)')
SPLASH_NIGHT = 'linear-gradient(172deg,#26304f 0%,#141a30 100%)'
# The launch tile is the icon one step lighter, so it reads as an object
# sitting on the sky rather than a hole cut in it.
TILE_DAWN = 'linear-gradient(168deg,#a8d0ec 0%,#f6dcbc 58%,#e29257 100%)'

SUN_RICH = 'radial-gradient(circle at 36% 32%,#fff6e6,#e09550 62%,#c67139 92%)'
SUN_PLAIN = 'radial-gradient(circle at 36% 32%,#fff6e6,#c67139 90%)'
SUN_FLAT = '#fff2dc'
GLOW = 'rgba(198,113,57,.34)'
MOON = '#f4f0e2'
NIGHT_INK = '#141a30'

# ── Tiers ─────────────────────────────────────────────────────────────────
# "Below 40px the lower band drops away and the sun grows — the silhouette
# survives at notification size." The threshold is the size the icon is
# *displayed* at, not the pixels it is rasterised to: a 20pt icon on a 3×
# screen is 60px of a 20pt drawing.
MASTER = dict(  # 248px — the square master: three-stop sun, glow, stars
    sun=0.387097, sun_top=0.31, sun_fill=SUN_RICH,
    glow_blur=0.217742, glow_spread=0.064516,
    bars=((0.451613, 0.94), (0.604839, 0.80)),
    bar_h=0.052419, gap=0.052419, bottom=0.177419,
    stars=((0.24, 0.104839), (0.71, 0.177419)), star=0.012097,
)
FULL = dict(MASTER, sun_fill=SUN_PLAIN, glow_blur=0, glow_spread=0, stars=())
COMPACT = dict(  # 40px — one band, larger sun
    sun=0.425, sun_top=0.28, sun_fill=SUN_PLAIN, glow_blur=0, glow_spread=0,
    bars=((0.60, 0.92),), bar_h=0.0625, gap=0, bottom=0.20, stars=(), star=0,
)
MICRO = dict(  # 20px — silhouette only
    sun=0.50, sun_top=0.26, sun_fill=SUN_FLAT, glow_blur=0, glow_spread=0,
    bars=((0.65, 0.95),), bar_h=0.10, gap=0, bottom=0.20, stars=(), star=0,
    sky=DAWN_MICRO,
)
# The launch tile keeps the full mark whatever size it is drawn at — it is
# the one place the mark is the whole picture.
TILE = dict(
    sun=0.384615, sun_top=0.31, sun_fill=SUN_PLAIN, glow_blur=0, glow_spread=0,
    bars=((0.448718, 0.94), (0.602564, 0.80)),
    bar_h=0.051282, gap=0.051282, bottom=0.192308, stars=(), star=0,
)


def tier_for(display_size):
    """The design's own size breaks, by displayed size.

    It draws four: 248 with stars and a glow, 96 and 64 with the full mark,
    40 with one band, 20 with the barest silhouette. The break between the
    full mark and one band therefore falls somewhere in the 24px the design
    does not draw — and it goes at 48 rather than 64 so that the 60pt icon on
    an iPhone home screen, the one everybody actually looks at, gets the mark
    the design leads with.
    """
    if display_size >= 128:
        return MASTER
    if display_size >= 48:
        return FULL
    if display_size >= 40:
        return COMPACT
    return MICRO


# ── Drawing ───────────────────────────────────────────────────────────────
def _px(fraction, box):
    return f'{fraction * box:.4f}px'


def _mark(tier, box, mono=False):
    """The sun and its bands, positioned inside a box of [box] pixels."""
    out = []

    for left, top in tier['stars']:
        s = _px(tier['star'], box)
        out.append(
            f'<i style="position:absolute;left:{left * 100}%;top:{top * 100}%;'
            f'width:{s};height:{s};border-radius:999px;background:#fff"></i>'
        )

    size = _px(tier['sun'], box)
    # A flat disc when the icon is a silhouette: a themed Android icon and a
    # 20px badge are both read by their shape, and a gradient only muddies it.
    fill = '#fff' if mono else tier['sun_fill']
    glow = ''
    if tier['glow_blur']:
        glow = (f';box-shadow:0 0 {_px(tier["glow_blur"], box)} '
                f'{_px(tier["glow_spread"], box)} {GLOW}')
    out.append(
        f'<i style="position:absolute;left:50%;top:{tier["sun_top"] * 100}%;'
        f'width:{size};height:{size};margin-left:-{_px(tier["sun"] / 2, box)};'
        f'border-radius:999px;background:{fill}{glow}"></i>'
    )

    bars = []
    for width, alpha in tier['bars']:
        # The design's monochrome swatch keeps the lower band at 60%, so the
        # two stay legible as two once the system tints them one colour.
        a = (0.6 if alpha < 0.9 else 1.0) if mono else alpha
        bars.append(
            f'<i style="display:block;width:{_px(width, box)};'
            f'height:{_px(tier["bar_h"], box)};border-radius:999px;'
            f'background:rgba(255,255,255,{a})"></i>'
        )
    out.append(
        f'<i style="position:absolute;left:0;right:0;'
        f'bottom:{_px(tier["bottom"], box)};display:flex;'
        f'flex-direction:column;align-items:center;'
        f'gap:{_px(tier["gap"], box)}">{"".join(bars)}</i>'
    )
    return ''.join(out)


def _page(body, width, height):
    return (
        '<html><head><meta charset="utf-8"><style>'
        'html,body{margin:0;padding:0;background:transparent;'
        'overflow:hidden}i{font-style:normal}'
        f'</style></head><body><div style="position:relative;'
        f'width:{width}px;height:{height}px">{body}</div></body></html>'
    )


def icon(size, tier, sky=True, inner=1.0, mono=False):
    """The app icon, flat and square.

    [inner] shrinks the mark into a centred fraction of the canvas — Android's
    adaptive icon draws on a 108dp canvas but only promises to show the middle
    66%, so the mark lives there and the sky takes the crop.
    """
    box = size * inner
    art = (f'<div style="position:absolute;left:50%;top:50%;'
           f'width:{box}px;height:{box}px;margin:-{box / 2}px 0 0 -{box / 2}px'
           f'">{_mark(tier, box, mono=mono)}</div>')
    ground = ''
    if sky:
        ground = (f'<div style="position:absolute;inset:0;'
                  f'background:{tier.get("sky", DAWN)}"></div>')
    return _page(ground + art, size, size)


def sky(width, height, fill):
    """A gradient on its own — the sky before anything is drawn on it."""
    body = f'<div style="position:absolute;inset:0;background:{fill}"></div>'
    return _page(body, width, height)


def tile(size, night=False, pad=0.5):
    """The rounded mark that sits at the centre of the launch screen.

    Rendered on a canvas [pad] larger than the tile on each side, because the
    design gives it a drop shadow and a shadow clipped at the tile's edge is
    not a shadow.
    """
    canvas = round(size * (1 + 2 * pad))
    radius = 0.282051 * size  # 22 of 78
    shadow = (f'0 {0.102564 * size:.3f}px {0.307692 * size:.3f}px '
              f'rgba(32,30,29,.16)')

    if night:
        # The same mark after dark: a crescent, cut by lifting a disc of the
        # night sky over the moon.
        d = 0.40 * size
        inner = (
            f'<i style="position:absolute;left:34%;top:26%;width:{d}px;'
            f'height:{d}px;border-radius:999px;background:{MOON};'
            f'box-shadow:0 0 {0.4 * size:.3f}px {0.12 * size:.3f}px '
            f'rgba(244,240,226,.28)"></i>'
            f'<i style="position:absolute;left:22%;top:20%;width:{d}px;'
            f'height:{d}px;border-radius:999px;background:{NIGHT_INK}"></i>'
            f'<i style="position:absolute;left:0;right:0;bottom:19%;'
            f'display:flex;flex-direction:column;align-items:center;'
            f'gap:{0.08 * size:.3f}px">'
            f'<i style="display:block;width:44%;height:{0.07 * size:.3f}px;'
            f'border-radius:999px;background:rgba(244,240,226,.9)"></i>'
            f'<i style="display:block;width:60%;height:{0.07 * size:.3f}px;'
            f'border-radius:999px;background:rgba(244,240,226,.6)"></i></i>'
        )
        fill = NIGHT
    else:
        inner = _mark(TILE, size)
        fill = TILE_DAWN

    body = (
        f'<div style="position:absolute;left:50%;top:50%;width:{size}px;'
        f'height:{size}px;margin:-{size / 2}px 0 0 -{size / 2}px;'
        f'border-radius:{radius:.3f}px;background:{fill};overflow:hidden;'
        f'box-shadow:{shadow}">{inner}</div>'
    )
    return _page(body, canvas, canvas), canvas
