# AtmosFlow

A weather app for iOS and Android, built in Flutter from the
[AtmosFlow Claude Design project](https://claude.ai/design/p/ac9e9aee-0640-47ce-8a80-5866410dc37a).

Six screens over a live animated sky: seven weather conditions, each with a day
and a night treatment, drifting clouds, falling rain and snow, lightning, and a
star field — all driven by real forecast data.

## Running it

```bash
flutter run
```

Code generation (freezed + json_serializable) runs separately, and must be run
after pulling or after editing any model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter analyze && flutter test
```

## Data

[Open-Meteo](https://open-meteo.com) — free, no API key, no signup. Forecasts
come from `api.open-meteo.com`, city search from `geocoding-api.open-meteo.com`,
and reverse geocoding from the platform's own geocoder.

Everything is requested and stored in canonical units — °C, km/h, metres, hPa —
and converted for display at the edge by `UnitFormatter`. The user's °C/°F and
km/h/mph choices never reach the domain layer.

## Layout

Feature-first, four layers per feature:

```
lib/
  core/
    theme/       AtmosTokens (the Organic design system), palettes, glass, motion
    failure/     AppFailure — the closed set of things that go wrong
    persistence/ SharedPreferences wiring
    widgets/     Shared chrome: screen transitions, section labels, segments
  features/
    weather/
      domain/       Immutable models + the WeatherRepository interface
      data/         Open-Meteo client, the design's fixtures, WMO code mapping
      application/  Riverpod providers
      presentation/ Home, Day Detail, and the ambient sky layers
    search/ settings/ onboarding/
  routing/       go_router shell + the floating tab bar
```

**Design system.** `lib/core/theme/atmos_tokens.dart` is a typed port of the
project's `_ds/organic-…/styles.css` — colours, ramps, spacing, radii and
shadows. Nothing else in the app hard-codes a hex or a px value; widgets read
`context.tokens`. `weather_palette.dart` holds the per-condition sky treatments,
transcribed from the prototype's `HOME_PALETTE` and `OB_MOODS`.

**State.** Riverpod 3, hand-written providers rather than codegen — the
`riverpod_generator` package requires Dart 3.9+ and this project targets the
installed 3.8.1 SDK. `forecastProvider` and `placeSearchProvider` opt out of
Riverpod 3's default retry-on-error: the design puts the user in charge with an
explicit "Try again" and pull-to-refresh.

**Animation.** Every duration and curve lives in `core/theme/motion.dart`,
transcribed from the design's CSS keyframes. The ambient sky repaints
independently of the content — Home feeds its scroll offset to `AmbientSky`
through a `ValueNotifier`, so parallax costs one repaint rather than a rebuild.
All of it honours `MediaQuery.disableAnimationsOf`, which is also how widget
tests get a still frame to settle on.

**Testing.** `FakeWeatherRepository` carries the design prototype's own fixtures
— San Francisco at 22°, the 8-entry hourly strip, the 24-point temperature curve
— so tests and offline development see exactly what the design showed.
