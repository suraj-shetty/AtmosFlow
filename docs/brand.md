# The app icon and the launch screen

Built from the **AtmosFlow Brand** design: one mark — a low sun over two
drifting bands of air — and a three-stage launch that treats the splash as
weather rather than as a wait.

## Where the design lives in the code

The design is CSS, so the most faithful rasteriser is a browser. The mark is
described once, in fractions of its own box, and Chrome draws it at whatever
size each slot wants:

```
tool/brand/mark.py     the design's geometry and palette → HTML
tool/brand/render.py   → every icon and launch asset on both platforms
```

```bash
python3 tool/brand/render.py
```

It is idempotent, and rendered at 248px against the brand file's own markup
the output is pixel-identical — that comparison is the test that the
transcription is right.

## The mark at four sizes

The design draws the mark four ways and the generator follows, choosing by
the size the icon is **displayed** at rather than the pixels it is rasterised
to: a 20pt icon is a 20pt icon whether the screen draws it with 20 pixels or
60.

| Displayed | What survives |
| --- | --- |
| 128pt and up | Stars, the sun's glow, its three-stop gradient |
| 48–127pt | The full mark: sun and both bands |
| 40–47pt | One band, and the sun grows |
| Below 40pt | Silhouette: two-stop sky, biggest sun, one band |

The design draws samples at 248, 96, 64, 40 and 20, so the break between the
full mark and the single band falls somewhere in the 24px it does not draw.
It goes at 48, which puts the 60pt iPhone home-screen icon — the one everyone
actually looks at — on the mark the design leads with.

Android takes the full mark at every size, because the design's own circle
and squircle swatches are drawn that way and those are what a launcher shows.
Its adaptive icon puts the sky in the background layer and the mark in the
foreground, sized into the middle 66% of the 108dp canvas, so whichever mask
the launcher applies it crops sky and never the mark. The monochrome layer
for themed icons is the same mark as a flat silhouette, keeping the lower
band at 60% so the two still read as two once the system tints them one
colour.

## The first two seconds

The design's timeline, as absolute marks from Flutter's first frame:

```
0ms    the static OS launch image
180ms  the sky starts moving
260ms  the wordmark rises 16px
600ms  it is in place, and held while the forecast resolves
800ms  the crossfade into the live condition begins
1200ms over
1500ms if the forecast is still not in, a hairline appears — never a spinner
```

Stage one is the OS launch image: a flat sky with the mark at rest, no text
and no motion. Stage two is `SplashGate`, which sits **over** the router
rather than inside it as a route — the design asks for one unbroken picture,
"the gradient never resets, it just becomes today", and a route of its own
would swap the sky out instead. Home is built and laid out underneath while
the splash is still up, so the handoff is a cross-dissolve between two skies.

The splash waits for a forecast when there is a saved place, and for nothing
when there is not — a first launch goes to onboarding, where there is nothing
to resolve.

### Two places the launch does not follow the mocks literally

Both are in service of the thing the section is actually about — that the
seam between the OS image and the first Flutter frame should be invisible.

**The mark does not sit in the middle.** The design centres it alone on the
cold-start mock and centres mark-plus-wordmark on the next one, which would
jog it 35pt upward the instant Flutter drew. It ships 35pt high on both.

**The launch image carries the splash's sky, not the icon's.** The
cold-start mock reuses the icon's own gradient (168°, three stops); the frame
after it — the one Flutter draws and then animates — is a shallower 172° with
four stops. Shipping the second as the launch image is what makes the two
frames identical.

### And two the platforms will not allow

**Android 12 and up draw their own splash**, which takes a flat colour and a
circular icon and nothing else. The dawn gradient's middle tone stands in
until Flutter's first frame; the gradient and the rounded tile arrive with it.

**"Between sunset and sunrise" becomes the OS dark appearance.** A launch
image is chosen before any code runs, so there is no sun to ask about. Both
the launch assets and the Flutter splash read the platform brightness, so
they agree with each other.
