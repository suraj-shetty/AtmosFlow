# AtmosFlow — Product Requirements

**Version 0.1.0+1 · As built, 26 August 2026**

A cross-platform weather app with home-screen widgets that keep their own time.
This document specifies everything the product currently does, written so a new
visual design can be built against it without losing a feature.

| | |
|---|---|
| **Platforms** | iOS 26 · Android |
| **Stack** | Flutter 3.47.1 · Dart 3.13.1 · Riverpod 3.3.2 |
| **Data** | Open-Meteo (free, keyless, no signup) |
| **Surfaces** | 7 screens + 5 widget layouts |
| **Tests** | 156 Dart · 18 Swift · 14 Kotlin |

---

## Contents

1. [How to read this](#1-how-to-read-this)
2. [Navigation map](#2-navigation-map)
3. [Screens](#3-screens)
4. [Data model](#4-data-model)
5. [Units and formatting](#5-units-and-formatting)
6. [Location and permissions](#6-location-and-permissions)
7. [Persistence and state](#7-persistence-and-state)
8. [Freshness and refresh](#8-freshness-and-refresh)
9. [Offline and failure](#9-offline-and-failure)
10. [Home-screen widgets](#10-home-screen-widgets)
11. [Background refresh](#11-background-refresh)
12. [Motion and accessibility](#12-motion-and-accessibility)
13. [Redesign constraints](#13-redesign-constraints)
14. [Status and gaps](#14-status-and-gaps)

---

## 1. How to read this

The goal is a redesign that keeps every feature. So each requirement is split
into the part a new design must preserve and the part it is free to reinvent.

> **Fixed** — behaviour, data, and rules. Changing these changes what the
> product *is*; they survive any visual direction. Where a number appears here
> it is load-bearing and tested.
>
> **Open** — layout, colour, typography, motion, iconography, copy tone.
> Nothing here is a requirement; it records what exists today so you can decide
> what to keep.

Requirement IDs (`FR-3.2`) are stable references for design review — they are
not a build order. Where a rule was arrived at by fixing a real bug, that is
noted, because those are the ones most easily lost in a rewrite.

---

## 2. Navigation map

Seven screens. One persistent root (Home), three modal presentations, and a
routing guard that decides where a cold launch lands.

```
Splash ──▶ redirect guard ──▶ /onboarding  or  /home

/home ──▶ /home/day/:index   (modal)
     ├──▶ /search            (modal)
     └──▶ /settings          (modal)

/search ──▶ /search/saved    (modal)

/onboarding ──▶ /search      (manual-entry escape hatch)
```

Modal presentations rise from the bottom edge and drop back out of it. Home
itself has no page-level transition — every screen body fades and lifts itself
in, so the route swap underneath is instant or the two would stack.

### FR-2.1 — Launch routing guard · *Shipped*

With no place selected, every route redirects to `/onboarding` — **except**
Search and Saved Locations, which stay reachable. Those two are the second half
of onboarding ("Enter Location Manually"), and blocking them would trap anyone
who declines location access. Once a place exists, `/onboarding` redirects
forward to `/home`.

**Fixed**
- Search reachable with no place selected
- Onboarding unreachable once a place exists
- Day Detail addressed by index into the 7-day list

**Open**
- Whether onboarding is a screen or a sheet
- Modal vs. push presentation
- Whether Saved Locations stays nested under Search

---

## 3. Screens

What each screen contains and what it is responsible for. Content is listed in
the order it currently appears; the order is design-owned unless noted.

### 3.1 Splash

#### FR-3.1 — Continuous-sky handoff · *Shipped*

The splash sits *over* the router rather than being a route of its own, so Home
is already built and laid out underneath while the splash is still visible. The
handoff is a cross-dissolve between two skies, not a screen swap — the gradient
never resets, it becomes today.

It clears when there is nothing left to wait for: a forecast has resolved, or
there is no saved place and the app is heading to onboarding anyway.

**Fixed**
- Splash never blocks longer than the forecast it waits on
- Dismissal is a dissolve, not a cut
- No spinner-only dead time before onboarding

**Open**
- Brand mark, wordmark, motion
- Minimum display duration
- Whether a sky appears at all

### 3.2 Onboarding

#### FR-3.2 — Two ways in, neither a dead end · *Shipped*

Wordmark, the line *"Your sky, beautifully forecasted."*, and two actions:
**Enable Location** (primary, shows "Locating…" while resolving) and **Enter
Location Manually** (secondary → Search).

A denied or failed location attempt raises a snackbar carrying the failure's own
copy, with a **Search** action on it — the refusal routes the user forward
instead of leaving them on a screen whose primary button just failed.

**Fixed**
- Manual entry always available, never gated behind a permission
- A location failure offers a route onward, not just an error
- Permission is requested on explicit tap, never on launch

**Open**
- Number of panels; currently single-screen
- Copy and value proposition
- Whether a permission primer precedes the OS dialog

### 3.3 Home

#### FR-3.3 — Content stack · *Shipped*

A full-bleed condition sky with the forecast scrolling over it, in this order:

- **Location bar** — place name (tappable → Search), search button, settings button
- **Hero** — current temperature, condition icon, condition label, "feels like"
- **Next 24 hours** — horizontal strip; tapping a chip reveals its precipitation chance
- **7-day forecast** — one row per day, high/low, condition; today marked; tap → Day Detail
- **Metric grid** — 2×2: Humidity, Wind, UV Index, Visibility

The sky is an animated ambient layer (sun, drifting shapes, particles, storm)
that parallaxes with scroll and **pauses when Home is covered** by another
route — nothing in Flutter stops a covered route's tickers, so left alone it
would keep scheduling frames behind a screen nobody can see.

**Fixed**
- All five content groups present
- Ambient motion pauses when covered and under reduced-motion
- Status bar glyph brightness follows the sky, not a fixed setting

**Open**
- Order and grouping of the five blocks
- Which four metrics lead (see §4.2 for the full set available)
- Whether the sky is literal, abstract, or absent

#### FR-3.4 — Refresh gesture · *Shipped*

Three affordances trigger the same refresh: **pull down past the trigger**,
**tap the header strip**, **tap the hero**. A custom "puck" indicator is drawn
out of the top edge by the pull and spins while fetching. The refreshing state
is held for a minimum beat so the spin reads even when the network is instant.
A refresh already in flight swallows further triggers.

**Fixed**
- Pull-to-refresh works and is not the only way
- Minimum visible refresh duration
- Re-entrancy guard

**Open**
- The puck itself — shape, icon, physics
- Whether tap-to-refresh survives
- Pull distance threshold

### 3.4 Day Detail

#### FR-3.5 — One day, expanded · *Shipped*

Reached by tapping any row in the 7-day list. Contains a **24-point temperature
line chart** for that calendar day, a **sun path** arc with a dot positioned by
progress through the daylight window, and a 2×2 detail grid: Humidity, **Wind
with a direction arrow** (rotated to point where the wind is going, labelled
with a 16-point compass), **UV Index** with band label and a proportional bar,
and Pressure.

UV here is the day's *maximum*; on Home it is the *current* reading. Both use
the same WHO bands (Low / Moderate / High / Very high / Extreme).

**Fixed**
- Temperature curve, sun path, and four detail metrics
- Day max UV here vs. current UV on Home
- Sun dot clamps at either end outside daylight

**Open**
- Chart style, axis treatment, whether the arc is an arc
- Grid vs. list for the metrics
- Whether hourly detail joins this screen

### 3.5 Search

#### FR-3.6 — Find and choose a place · *Shipped*

A "Use my location" action, a text field (*"Search for a city"*), live results,
and the saved list below with a link through to Saved Locations. Selecting any
result adds it to the saved list and makes it current, then returns to Home.

Queries are **debounced 300 ms**. Each keystroke asks for a different provider
family member, disposing the previous one — so a fast typist cancels their own
in-flight requests rather than spraying them. Empty query returns nothing
without a request. No retry on failure.

Result rows show a live condition icon and temperature for places already
fetched. No results is a distinct empty state naming the query, not an error.

**Fixed**
- 300 ms debounce; no request on empty query
- Selecting saves and selects in one step
- Distinct empty state vs. failure state

**Open**
- Whether saved locations appear on this screen at all
- Recent searches, favourites, map picker
- Result row content

### 3.6 Saved Locations

#### FR-3.7 — The list, at full size · *Shipped*

Every saved place as a row with its own live forecast — condition icon and
current temperature, each fetched independently. Tapping selects and returns to
Home.

**Fixed**
- Each row carries its own live reading
- Rows degrade gracefully before their forecast lands

**Open**
- Whether this is a screen or merges into Settings
- Swipe actions, drag handles

### 3.7 Settings

#### FR-3.8 — Units and location management · *Shipped*

Two cards. **Units**: temperature (°C / °F) and wind speed (km/h / mph), each a
segmented control. A live temperature chip flips on its Y axis whenever the unit
changes — the setting demonstrates itself.

**Manage Locations**: a reorderable list with drag handles, each row showing the
place name and its current temperature, with a remove button. Empty state: "No
saved locations yet."

**Fixed**
- Both unit choices, persisted, applied everywhere at once
- Reorder and remove
- Unit change re-renders every temperature in the app immediately

**Open**
- The flip animation
- Card vs. list grouping
- Additional settings (theme, precipitation units, notifications)

---

## 4. Data model

Everything is fetched from Open-Meteo in canonical units and converted only at
the point of display. A redesign inherits this whole surface — including fields
not currently shown anywhere.

### 4.1 Conditions

Every WMO weather code the API returns is collapsed into **seven conditions**,
each of which needs a day and a night treatment.

| Condition | Label | Needs |
|---|---|---|
| `clear` | Clear | Day + night icon, day + night sky |
| `cloudy` | Cloudy | Day + night icon, day + night sky |
| `fog` | Fog | Day + night icon, day + night sky |
| `drizzle` | Drizzle | Day + night icon, day + night sky |
| `rain` | Rain | Day + night icon, day + night sky |
| `snow` | Snow | Day + night icon, day + night sky |
| `storm` | Storm | Day + night icon, day + night sky |

That is 14 sky treatments and 14 icons in the app, plus a separate five-band sky
system for the widgets (§10.2). Sizing the redesign work: this matrix is the
bulk of it.

### 4.2 Fields available

| Group | Fields | Shown today |
|---|---|---|
| Current | `temperature`, `feelsLike`, `condition`, `isNight`, `humidity`, `windSpeed`, `windDirection`, `uvIndex`, `visibilityMetres`, `pressureHpa` | All but pressure (Day Detail only) |
| Hourly | `time`, `temperature`, `condition`, `isNight`, `precipitationProbability` | Next 24, precipitation on tap |
| Daily (×7) | `date`, `high`, `low`, `condition`, `sunrise`, `sunset`, `uvIndexMax`, 24 hourly temperatures | All |
| Place | `id`, `name`, `latitude`, `longitude`, `country`, `admin1`, `timezone` | Name only |

> **Free for the taking.** `country` and `admin1` are fetched, stored, and never
> displayed — a redesign could disambiguate two cities of the same name at no
> data cost. `feelsLike` and pressure are likewise under-used.

### 4.3 Time handling

#### FR-4.1 — Wall-clock vs. absolute time · *Subtle*

Open-Meteo returns local wall-clock stamps *with no zone suffix*, so they parse
as device-local. Comparing those against a UTC instant compares absolute time
and lands the wrong hour whenever the place and the device are in different
zones.

The app therefore rebuilds the place's clock in the same naive shape
(`Forecast.localNow`) and compares wall-clock to wall-clock throughout. The
place's UTC offset is carried on every forecast and published to the widgets.

**Fixed**
- Looking up Tokyo from London shows Tokyo's hours
- Hourly strip starts at the place's current hour
- Never compare a naive stamp against a UTC instant

**Open**
- Whether the place's local time is displayed
- Relative vs. absolute time labels

---

## 5. Units and formatting

One formatter owns every user-facing number, so a unit change is a single
dependency and the same "22°" appears everywhere it should.

| Value | Canonical | Display | User choice |
|---|---|---|---|
| Temperature | °C | `22°` — degree sign, no letter | °C / °F |
| Temperature (spoken) | °C | `22 °C` — for accessibility | °C / °F |
| Wind | km/h | `12 km/h` | km/h / mph |
| Visibility | metres | `12 km` | Always metric |
| Humidity | % | `58%` | — |
| Pressure | hPa | `1013 hPa` | — |

### FR-5.1 — Formatting never happens in a widget · *Shipped*

All values stay canonical through the domain and convert only at the edge. Two
display forms exist for temperature: the bare `22°` the design shows, and
`22 °C` where the unit must be said out loud. Visibility is deliberately always
metric.

**Fixed**
- Both unit toggles persist and apply globally and instantly
- Rounding to whole numbers throughout
- A spoken form exists for temperature

**Open**
- Whether visibility gains an imperial option
- Decimal precision
- Adding pressure / precipitation unit choices

---

## 6. Location and permissions

### FR-6.1 — Resolving the device's position · *Shipped*

Checks the location service is on, requests permission if undetermined, then
fetches a **low-accuracy** position — a weather app does not need metres. The
coordinate is reverse-geocoded by the platform geocoder into a named place.

Every plugin exception is translated into one of the app's own failures, so the
UI has a single closed set to switch on. There is **no retry**: a refused
permission or a switched-off location service is a decision, not a blip.

A geocoding failure is treated as cosmetic — the place falls back to the label
"Current Location" rather than denying someone their local forecast.

**Fixed**
- Low accuracy only
- No silent retry on refusal
- Naming failure never blocks the forecast
- Permanently-denied gets different copy from not-yet-asked

**Open**
- Whether a permission primer precedes the dialog
- Deep link to OS settings when permanently denied
- Background location (not currently used)

### 6.1 Failure copy

Five failure kinds, each with copy shown verbatim to the user. A test asserts
none is empty or leaks a debug string.

| Kind | Copy |
|---|---|
| `network` | Couldn't reach the forecast. Check your connection. |
| `notFound` | No forecast for that location. |
| `locationDenied` | Location access is needed to show your local forecast. |
| `locationDenied` (permanent) | Location access is off. Enable it in Settings to use your location. |
| `malformedResponse` | The forecast came back in a format we could not read. |
| `unknown` | Something went wrong. Pull to try again. |

The "unknown" string names a gesture. If the redesign drops pull-to-refresh,
this copy changes with it.

---

## 7. Persistence and state

Three keys in shared preferences, plus a shared store the widgets read. No
account, no server, no sync.

| Key | Holds | Notes |
|---|---|---|
| `savedLocations` | Ordered list of places as JSON | Order is user-controlled via drag |
| `selectedPlaceId` | Which place Home shows | Falls back to the first saved place if the id is missing |
| `settings` | Temperature and wind unit | — |

### FR-7.1 — Saved list rules · *Shipped*

Adding a place that is already saved is a no-op that still returns the place, so
callers can select it without caring which happened. Removal is by id.
Reordering writes immediately. A corrupt stored list degrades to empty rather
than crashing.

An empty saved list means **no place is selected**, whatever `selectedPlaceId`
says — which is what sends a fresh install to onboarding.

**Fixed**
- No duplicates
- Order persists
- Corrupt data degrades, never crashes
- Empty list ⇒ no selection

**Open**
- A cap on saved places (none today)
- Whether "current location" is a pinned first entry

---

## 8. Freshness and refresh

Five durations govern how old a reading may be before something acts. They do
different jobs and are deliberately different numbers.

| Setting | Value | Job |
|---|---|---|
| App cache TTL | 15 min | Past this, a resume refetches; an unwatched place is evicted |
| Background fetch | 1 hour | Requested cadence for the OS (advisory — see §11) |
| Skip-if-fresh guard | 20 min | Stops a background run refetching what the app just published |
| Widget staleness | 3 hours | Past this the widget shows age instead of a clock |
| Widget redraw | 30 min / hourly | Android floor / iOS timeline ticks |

### FR-8.1 — Resume refetches a stale reading · *Shipped*

Returning to the app invalidates every held forecast when the selected place's
reading has passed 15 minutes. The refresh is silent — the screen keeps its
numbers while new ones land, rather than flashing a spinner.

The *whole family* is invalidated, not just the visible place, because Saved
Locations holds a forecast per row and they go stale together.

**Fixed**
- Resume with a stale reading refetches
- Resume with a fresh one does not spend a request
- Refresh is silent when numbers are already on screen

**Open**
- The 15-minute figure
- Whether a "last updated" line appears in the app (it does not today)

### FR-8.2 — Unwatched places are let go · *Shipped*

A forecast nothing is watching expires after the same 15 minutes. One search for
"London" was otherwise leaving nine forecasts pinned in memory for the life of
the process.

**Fixed**
- Search results do not accumulate indefinitely
- A screen returning within the window keeps its cached data

**Open**
- Nothing user-visible — this is invisible when correct

> **Known gap, accepted.** A session that never goes to the background holds
> whatever it is watching, however old. Every realistic way of leaving a weather
> app goes through a resume, and refetching under someone actively reading the
> screen is a design decision rather than an obvious win. Worth revisiting if
> the redesign introduces long-dwell surfaces.

---

## 9. Offline and failure

The governing principle: a reading from ten minutes ago is worth far more than a
screen announcing it could not reach the network.

### FR-9.1 — A failed refresh keeps the forecast · *Shipped*

When a refresh fails and a previous reading exists, the reading **stays on
screen** and the failure arrives as a snackbar. Only a cold start with nothing
cached shows the full-screen error, because then the failure is genuinely all
there is — that state carries the failure copy and a **Try again** button.

This was a real bug: the app was replacing a perfectly good forecast with an
error message the moment a pull-to-refresh failed. Its own widget was already
behaving better.

**Fixed**
- Never trade a usable reading for an error message
- Cold failure gets a full screen with a retry
- Failures are surfaced somewhere, never swallowed

**Open**
- Snackbar vs. inline banner vs. a staleness marker in the header
- Whether the app shows its reading's age the way the widget does

> **A design opportunity.** The widget states its reading's age past three
> hours; the app never states its age at all. If the redesign wants one
> genuinely new idea that costs no data, showing the app's own reading age — and
> letting it degrade gracefully rather than erroring — is the most natural one
> available.

### 9.1 Failure surfaces by screen

| Screen | With cached data | Without |
|---|---|---|
| Home | Snackbar; forecast stays | Full-screen error + Try again |
| Search | — | Inline message under the field |
| Onboarding | — | Snackbar with a **Search** action |
| Saved rows | Row shows a pin icon, no temperature | Same |
| Widget | Keeps drawing, marks its age | Placeholder tile |

---

## 10. Home-screen widgets

The widgets are separate processes that cannot call the weather API. They draw
what the app last left in a shared store — and, crucially, they resolve time of
day themselves rather than being handed a pre-baked answer.

### 10.1 Surfaces

| Surface | Platform | Layout |
|---|---|---|
| `systemSmall` | iOS | Square tile, compact type |
| `systemMedium` | iOS | Landscape tile |
| `systemLarge` | iOS | Square tile, larger type |
| Lock Screen accessory | iOS | Monochrome — glyph, temperature, caption |
| 4×2 home tile | Android | Landscape, 280×144dp, resizable |

The Lock Screen surface renders through a monochrome vibrancy filter, so no
gradient survives — only the reading itself, in the same order.

### 10.2 The five skies

Widgets use a five-band sky system anchored to the sun rather than the clock —
dawn is the hour around sunrise *wherever the place is*, not 5 AM everywhere.

| Sky | Band | Copy colour |
|---|---|---|
| Dawn | 1h before sunrise → 90 min after | White |
| Morning | Dawn end → solar noon | Ink |
| Afternoon | Solar noon → 90 min before sunset | Ink |
| Evening | 90 min before sunset → 1h after | White |
| Night | Everything else | White |

Solar noon is the midpoint of sunrise and sunset, so a long Reykjavík summer day
splits the same way a short one does.

#### FR-10.1 — Ingredients, not answers · *Shipped*

The app publishes the place's UTC offset and a **schedule of every sky change
for the next 36 hours**, rather than a single resolved sky. The widget looks up
the band for the moment it is actually drawing.

Without this, a widget last updated at 3 PM would still be painting an afternoon
sky at midnight — stale numbers that *look* live, which is worse than stale
numbers that look stale.

**Fixed**
- Widget advances through the day with no network
- Sky banding rules live in one place (Dart), never re-implemented natively
- 36-hour schedule horizon

**Open**
- The five gradients themselves
- Whether five bands is the right number
- Tile composition at each size

#### FR-10.2 — One slot, two jobs · *Shipped*

A single slot shows **the hour the reading was taken** while it is fresh, and
**how old it is** once past three hours — "4h ago", "Yesterday", "3d ago".
Deliberately coarse: to the minute is a precision nobody reads a weather widget
for.

The clock is the *place's* hour, formatted in whichever of 12- and 24-hour **the
device is set to** — read from the system formatter on both platforms, never a
hand-written format string.

**Fixed**
- 12/24-hour follows the OS setting
- Time shown is the place's, not the device's
- Past 3 hours the widget admits its age

**Open**
- Whether age and clock share a slot or separate
- The 3-hour threshold
- Age phrasing

### 10.3 Shared store contract

Eight keys, flat strings — all either platform's shared store holds. Every
instant crosses as epoch seconds, UTC.

| Key | Example |
|---|---|
| `condition` | `cloudy` |
| `conditionLabel` | `Cloudy` |
| `temperature` | `22°` |
| `humidity` | `91%` |
| `place` | `Bengaluru` |
| `utcOffsetMinutes` | `330` |
| `skySchedule` | `1787684159:night,1787528280:dawn,…` |
| `updatedAt` | `1787684159` |

Values cross as the strings they will be printed as, because the widget process
has no access to the app's settings or locale plumbing. Only the condition
crosses as an identifier, because the widget draws with it.

---

## 11. Background refresh

So the widget is not simply as old as the last time someone opened the app.

### FR-11.1 — Headless fetch · *Verified on device*

An hourly periodic task runs in a headless Dart isolate — no UI, no navigation,
no app state — that reuses the app's own repository, formatter and publisher
rather than a second implementation. That is what stops the widget drifting from
what the app would have shown.

It skips if no place is selected (onboarding unfinished — not a failure), skips
if the stored reading is under 20 minutes old, and reports failure silently so
the OS retries later. The widget goes on showing its last good reading with an
honest age against it.

**Fixed**
- Background path uses the same code as the foreground
- Guards against wasted fetches
- Failures are silent — nobody is watching

**Open**
- The 1-hour request
- Whether Wi-Fi-only or charging constraints are added

> **What this can and cannot promise.** "Best effort" and nothing firmer. iOS
> decides when a background refresh runs from how the person actually uses the
> app: a few times a day is realistic, hourly is not, and with Background App
> Refresh off or Low Power Mode on it is never. Android is steadier but still
> batches.
>
> Confirmed firing unprompted on a physical iPhone — two independent
> observations, one at 00:25 with the app closed. The widget's own schedule is
> what makes the variability acceptable: between fetches it still moves through
> the day correctly and says how old its numbers are.

---

## 12. Motion and accessibility

### 12.1 Motion inventory

- **Ambient sky** — continuous sun, drifting shapes, particles, storm layers; parallaxes with scroll
- **Screen transition** — every screen body fades and lifts itself in; modals rise from the bottom edge with the gradient riding the slide
- **Refresh puck** — drawn out by pull, spins while fetching
- **Metric tiles** — staggered entrance, 60 ms apart
- **Temperature chip** — Y-axis flip on unit change

### FR-12.1 — Reduced motion is honoured · *Shipped*

With animations disabled at the OS level the app draws a still sky. This is
load-bearing beyond accessibility — the golden test suite relies on it, since a
looping sky means a test that never settles.

**Fixed**
- Every looping animation has an off switch
- Ambient motion pauses behind covered routes

**Open**
- What "still" looks like — currently a static gradient

> **Weakest area of the product.** Three files touch semantics in an app built
> largely from custom painters. The location bar is properly labelled; the
> charts, sun path, metric tiles and sky are not. To VoiceOver or TalkBack, most
> of Home is an unlabelled blur. A redesign is the cheapest moment this will
> ever be fixed — the labels are being written either way.

---

## 13. Redesign constraints

The short list. Everything a new visual direction must be able to accommodate,
gathered in one place.

1. **14 app sky treatments** — 7 conditions × day/night — each supplying a
   three-stop gradient plus four text roles (hero, chrome, sub, kicker) that
   stay legible on it.
2. **5 widget skies** — dawn, morning, afternoon, evening, night — a separate
   system from the app's day/night pair, each declaring whether it takes white
   or ink copy.
3. **14 condition icons**, day and night variants.
4. **Five widget layouts** across two platforms, drawn natively in SwiftUI and
   Android RemoteViews — *not* Flutter. Whatever the design, these are rebuilt
   twice by hand.
5. **Monochrome fallback** for the Lock Screen surface, where no colour
   survives.
6. **Status bar legibility** — glyph brightness is computed from the sky, so any
   new sky must resolve to a clear light-or-dark answer.
7. **A still state** for every animation.
8. **Two type roles minimum** — the current build ships a display face and a
   body face, with the display face used for temperatures and headings.

> **Cheapest high-value additions**, if the redesign wants new surface area
> without new data: reading age in the app (§9), place disambiguation using the
> already-stored country and region (§4.2), and `feelsLike` or pressure promoted
> out of Day Detail.

---

## 14. Status and gaps

### 14.1 Verification

| | |
|---|---|
| ✅ | **156 Dart tests** — unit, widget, and a 21-image golden suite covering every condition in both day and night |
| ✅ | **18 Swift + 14 Kotlin tests** — sky lookup, staleness, clock formatting on both platforms. The render tests are not assertions: two functions on the iOS side draw all 105 tiles and then the 35 backgrounds under them, for the contact sheet and the contrast check. The Kotlin one is instrumented, so it wants a device and CI does not run it |
| ✅ | **Background refresh proven on a physical iPhone** — fires unprompted with the app closed |
| ✅ | **Android background worker proven** on emulator, end to end |
| ⚠️ | **No CI** — nothing runs any of the above automatically |
| ⚠️ | **Accessibility largely unaddressed** outside the location bar |

### 14.2 Not built

- No notifications or severe-weather alerts
- No precipitation radar or map
- No account, sync, or server component
- No theme setting — appearance follows the weather, not the user
- No air quality, pollen, or marine data (Open-Meteo offers all three keylessly)
- No watch app, no Android complications
- No localisation — copy is English-only, though the 12/24-hour clock does
  follow the device

> **On scoping the redesign.** The feature set above is small and complete. The
> expensive part of any new direction is not the seven screens — it is the 14
> sky treatments, the 14 icons, and the five natively-built widget layouts.
> Budget accordingly, and consider whether the day/night pair and the five-band
> widget system can be unified into one set.

---

*Every behaviour marked **Fixed** in this document is covered by at least one
test. Numbers quoted as durations are the values in source, not aspirations.*
