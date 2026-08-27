# Home-screen widgets

Built from the **AtmosFlow Widgets** design: three tiles, seven conditions,
five times of day — 105 combinations in all, every one of them the same
recipe. A time-of-day sky, an optional dusk wash, a condition veil, and a
handful of absolutely-positioned shapes over the top.

## Where the design lives in the code

The design writes those shapes as inline CSS. Hand-transcribing 35 layer sets
into two languages would be 70 chances to mistype an alpha, so it is read
once and generated twice:

```
tool/widget_spec/ambient.json        the design's own inline CSS, extracted
tool/widget_spec/parse_ambient.py    that CSS → a typed model
tool/widget_spec/ambient_model.json  the model — 7 conditions × 5 skies
tool/widget_spec/emit_swift.py       → ios/AtmosFlowWidget/AmbientCatalog.swift
tool/widget_spec/emit_kotlin.py      → android/…/widget/AmbientCatalog.kt
```

Both generated files carry a "do not edit" header. When the design moves,
re-read it and re-run the two emitters.

Everything geometric is a fraction of the tile's reference size, which is how
one set of numbers serves a 160pt tile, a 200pt one and a 280pt one. The
exceptions are hairlines — a rain streak is 2pt wide at every size, exactly as
the design has it.

The condition glyphs stay in the form the design wrote them, as SVG `d`
strings. Android reads them with `androidx.core.graphics.PathParser`; iOS has
a small reader of its own in `SVGPath.swift`, covering the commands these
seven icons use and nothing more.

## Two places the widgets cannot follow the design literally

**They do not animate.** WidgetKit renders a still frame — a widget has no run
loop — and an Android app widget is a `RemoteViews` tree the launcher hosts,
with the same limitation. This is a platform boundary, not a shortcut.

Dropping the motion outright would have left every rain streak parked off the
top edge where its keyframe starts, so the scene is *sampled* instead: each
shape is drawn where its own animation has it at one instant. Because the
design gives every drop and every star its own duration and delay, a single
instant scatters them the way watching the prototype for a moment would.

That instant is 2.944s — 92% of the storm's 3.2s `rainFallFlash` cycle, the
one frame where the lightning is at full strength. A widget shows the same
picture for minutes at a time, so a storm sampled anywhere else in that cycle
would be a storm with no lightning in it. Both platforms use the same number,
so they draw the same frame.

**Two of the three iOS surfaces are not the surfaces they are named after.**
An iOS Lock Screen widget renders through a monochrome vibrancy filter, and a
Control Center control is a button with a symbol in it — neither can carry a
colour gradient with a sun in it. What the design's three tiles really are is
one square layout at two type scales and one landscape layout, which is
exactly the set of families WidgetKit offers:

| Design tile | Rendered as |
| --- | --- |
| iOS Lock Screen · Small (160) | `systemSmall` |
| iOS Control Center · Square (200) | `systemLarge` |
| Android Home Screen · 4×2 (280) | `systemMedium`, and the Android widget |

There is also a real `accessoryRectangular` Lock Screen widget. It shows the
reading in the order the design puts it in; the sky cannot come along.

**Rain and storm print white at every hour.** The design carries two sets of
copy colours and picks between them by sky — white on dawn, evening and night,
ink on morning and afternoon. That reads as a rule about the sky, but it is
really a rule about the tile, and for five of the seven conditions the two are
the same thing. Rain's veil is rgba(52, 58, 80, .58) and the storm's is
rgba(24, 26, 44, .64), heavy enough that a bright morning arrives at the copy
as dark as an evening: ink on `Rain|Morning` measured 4.1:1 for the
temperature and 2.3:1 for the caption, and the storm was worse. Those four
tiles now take the white set, which is what `WidgetPalette` on each side is
for.

On Android the whole tile is painted into one bitmap rather than assembled
from `RemoteViews`. A `RemoteViews` tree cannot draw gradients, glows or an
arbitrary path, and cannot reach the app's bundled Figtree either. The cost is
that its text does not follow the system font scale, which is why the widget
carries a full content description.

## Data

The widgets cannot fetch a forecast — they draw whatever the app last left in
a shared store. `widgetMirrorProvider` watches the forecast Home is showing
and writes it out on every change, over a hand-rolled method channel:

- **iOS** — App Group `group.com.surajshetty.atmosFlow`, then
  `WidgetCenter.reloadAllTimelines()`.
- **Android** — SharedPreferences `atmos_flow.widget`, then a repaint of every
  placed widget.

Numbers cross already formatted, because the extension has no access to the
app's unit settings. Only the condition and the sky cross as identifiers,
because those are the two things the widget *draws* with.

## Seeing them

Both platforms carry a render harness that draws all 35 skies to PNGs — a
contact sheet is the only practical way to check a matrix this size.

```bash
xcodebuild test -project ios/Runner.xcodeproj -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RunnerTests/WidgetRenderTests \
  -parallel-testing-enabled NO
```

```bash
cd android && ./gradlew :app:connectedDebugAndroidTest
```

Each prints the directory it wrote to. The sheet in the README is the iOS
square tiles from that directory, laid out five skies across and seven
conditions down:

```bash
python3 tool/brand/widgets.py <the directory it printed>
```

That step is worth doing with the script rather than by hand. Every tile comes
out of `ImageRenderer` clipped to a rounded rectangle, so its corners are
transparent; flattening them onto anything but the page's own cream leaves
four wedges on all thirty-five.

## Regenerating the Xcode target

The extension is not something `flutter create` knows how to make, and a
hand-edited `project.pbxproj` is a merge conflict waiting to happen, so it is
built by a script — idempotently, so running it twice leaves one target:

```bash
ruby tool/add_ios_widget_target.rb
```
