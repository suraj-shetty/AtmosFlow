import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failure/app_failure.dart';
import '../../../../core/theme/atmos_tokens.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/weather_icons.dart';
import '../../../../core/theme/weather_palette.dart';
import '../../../../core/widgets/screen_transition.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../routing/app_router.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/weather_providers.dart';
import '../../domain/forecast.dart';
import '../../domain/weather_condition.dart';
import '../ambient/ambient_sky.dart';
import 'widgets/daily_row.dart';
import 'widgets/hourly_strip.dart';
import 'widgets/metric_tile.dart';
import 'widgets/pull_to_refresh.dart';
import 'widgets/refresh_puck.dart';

/// The main screen: a full-bleed condition sky with the forecast scrolling
/// over it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Feeds the parallax without rebuilding the content on every frame.
  final _scrollOffset = ValueNotifier<double>(0);

  /// How far the list has been dragged past its top, 0–1 against the trigger.
  /// Only the puck listens, so a pull never rebuilds the forecast.
  final _pull = ValueNotifier<double>(0);

  /// Drives the refresh puck. The pull gesture and the design's tap targets
  /// both set it, so there is only ever one indicator on screen.
  bool _refreshing = false;

  @override
  void dispose() {
    _scrollOffset.dispose();
    _pull.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _scrollOffset.value = notification.metrics.pixels;
    }
    return false;
  }

  Future<void> _refresh(Forecast forecast) async {
    if (_refreshing) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _refreshing = true);
    ref.invalidate(forecastProvider(forecast.place));
    try {
      await Future.wait([
        ref.read(forecastProvider(forecast.place).future),
        // The design holds the refreshing state for a beat so the puck's spin
        // reads even when the network is instant.
        Future<void>.delayed(Motion.refreshMinimum),
      ]);
    } catch (error) {
      // Nobody awaits this — the puck fires it and the gesture is over — so
      // an escaping failure would go nowhere but the console. The reading on
      // screen is still the last good one, so the failure is said out loud
      // rather than drawn over the top of it.
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            (error is AppFailure ? error : const AppFailure.unknown()).message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(currentForecastProvider);
    if (async == null) return const SizedBox.shrink();

    return async.when(
      // A failed refresh does not take the forecast away. Riverpod holds the
      // last good value alongside the error, and a reading from ten minutes
      // ago is worth vastly more to someone in a tunnel than a screen saying
      // it could not reach the network — which is the same judgement the
      // widget already makes when it keeps drawing and marks its own age.
      // With no value to fall back on there is nothing to show but the
      // failure, and this falls through to `error` as before.
      skipError: true,
      loading: () => const _HomeScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _HomeScaffold(
        child: _HomeError(
          failure: error is AppFailure ? error : const AppFailure.unknown(),
          onRetry: () {
            final place = ref.read(selectedPlaceProvider);
            if (place != null) ref.invalidate(forecastProvider(place));
          },
        ),
      ),
      data: (forecast) => _buildLoaded(context, forecast),
    );
  }

  Widget _buildLoaded(BuildContext context, Forecast forecast) {
    final tokens = context.tokens;
    final current = forecast.current;
    final palette = WeatherPalette.resolve(
      tokens,
      current.condition,
      isNight: current.isNight,
    );
    final formatter = ref.watch(unitFormatterProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Search, Settings and Day Detail cover Home completely, and nothing in
    // the framework stops a covered route's tickers: left alone the sky would
    // keep rebuilding and re-scheduling frames behind a screen no one can
    // see. `ModalRoute.of` rebuilds this when the route stops being current.
    final visible = ModalRoute.of(context)?.isCurrent ?? true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The status bar sits directly on the sky, so it reads the sky rather
      // than a setting: light glyphs over a night or storm gradient, dark
      // ones over a clear morning. `statusBarBrightness` is what iOS reads
      // and `statusBarIconBrightness` what Android does; they are opposites
      // of each other, which is why both are spelled out here.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: palette.brightness,
        statusBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ScreenTransition(
              // The sky is the backdrop every glass card on this screen
              // blurs, so it belongs inside the entrance — see
              // [ScreenTransition.background].
              background: BoxDecoration(gradient: palette.gradient),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AmbientSky(
                      condition: current.condition,
                      isNight: current.isNight,
                      scrollOffset: _scrollOffset,
                      enabled: visible && !reduceMotion,
                    ),
                  ),
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,

                      // The gesture and the indicator are both the app's: the pull
                      // draws the puck out of the top edge and, past the trigger,
                      // starts the same refresh a tap on the hero would.
                      child: PullToRefresh(
                        pull: _pull,
                        refreshing: _refreshing,
                        onRefresh: () => _refresh(forecast),
                        child: ListView(
                          physics: PullToRefresh.physics,
                          padding: const EdgeInsets.only(top: 72, bottom: 104),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 18,
                                children: [
                                  // The design refreshes on a tap of the header
                                  // strip or the hero, either side of the controls
                                  // that sit inside them.
                                  GestureDetector(
                                    onTap: () => _refresh(forecast),
                                    child: _LocationBar(
                                      name: forecast.place.name,
                                      color: palette.accentText,
                                      onSearch: () =>
                                          context.push(Routes.search),
                                      onSettings: () =>
                                          context.push(Routes.settings),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _refresh(forecast),
                                    child: _Hero(
                                      temperature: formatter.temperature(
                                        current.temperature,
                                      ),
                                      condition: current.condition.label,
                                      feelsLike: formatter.temperature(
                                        current.feelsLike,
                                      ),
                                      palette: palette,
                                      conditionIcon: WeatherIcons.forCondition(
                                        current.condition,
                                        isNight: current.isNight,
                                      ),
                                    ),
                                  ),
                                  _Section(
                                    label: 'Next 24 hours',
                                    color: palette.kickerText,
                                    child: HourlyStrip(
                                      hours: forecast.next24Hours,
                                      palette: palette,
                                    ),
                                  ),
                                  _Section(
                                    label: '7-day forecast',
                                    color: palette.kickerText,
                                    child: Column(
                                      spacing: 8,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < forecast.daily.length;
                                          i++
                                        )
                                          DailyRow(
                                            day: forecast.daily[i],
                                            isToday: i == 0,
                                            lowLabel: formatter.temperature(
                                              forecast.daily[i].low,
                                            ),
                                            highLabel: formatter.temperature(
                                              forecast.daily[i].high,
                                            ),
                                            onTap: () =>
                                                context.push(Routes.day(i)),
                                            palette: palette,
                                          ),
                                      ],
                                    ),
                                  ),
                                  _MetricGrid(
                                    current: current,
                                    palette: palette,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RefreshPuck(
            refreshing: _refreshing,
            pull: _pull,
            // The design shows the sky's own body for a clear sky and a
            // cloud for every other condition.
            icon: current.condition == WeatherCondition.clear
                ? WeatherIcons.forCondition(
                    current.condition,
                    isNight: current.isNight,
                  )
                : WeatherIcons.forCondition(WeatherCondition.cloudy),
            color: palette.accentText,
          ),
        ],
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.tokens.bg, child: child);
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AtmosTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AtmosTokens.space3,
          children: [
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.name,
    required this.color,
    required this.onSearch,
    required this.onSettings,
  });

  final String name;
  final Color color;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // The place name is the design's other way into Search — it carries
        // the same handler as the search button beside it.
        Flexible(
          child: Semantics(
            button: true,
            container: true,
            excludeSemantics: true,
            label: 'Change location, currently $name',
            child: GestureDetector(
              onTap: onSearch,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                // Matches the icon buttons opposite, so the whole header
                // strip is a comfortable target rather than just the glyphs.
                height: 38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(WeatherIcons.pin, size: 16, color: color),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AtmosTokens.fontHeading,
                          fontSize: 17,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            GlassIconButton(
              icon: WeatherIcons.search,
              onPressed: onSearch,
              color: color,
              tooltip: 'Search locations',
            ),
            GlassIconButton(
              icon: WeatherIcons.settings,
              onPressed: onSettings,
              color: color,
              tooltip: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.temperature,
    required this.condition,
    required this.feelsLike,
    required this.palette,
    required this.conditionIcon,
  });

  final String temperature;
  final String condition;
  final String feelsLike;
  final WeatherPalette palette;
  final IconData conditionIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        Text(
          temperature,
          style: TextStyle(
            fontFamily: AtmosTokens.fontBody,
            fontSize: 96,
            // The design asks for `font-weight:200`, but its Google Fonts
            // import only loads Figtree 400/600/700 and browsers never
            // synthesise a lighter face — so the prototype renders the hero
            // in Regular. Matching what it draws, not what it declares.
            fontWeight: FontWeight.w400,
            height: 1,
            letterSpacing: -0.03 * 96,
            color: palette.text,
            shadows: palette.heroTextShadow,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            Icon(conditionIcon, size: 22, color: palette.text),
            Text(
              condition,
              style: TextStyle(fontSize: 17, color: palette.text),
            ),
          ],
        ),
        Text(
          'Feels like $feelsLike',
          style: TextStyle(fontSize: 13, color: palette.subText),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.child,
    required this.color,
  });

  final String label;
  final Widget child;

  /// The kicker sits directly on the sky, so it takes the palette's own
  /// on-sky colour rather than the design's hardcoded neutral-700.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SectionLabel(label, color: color),
        child,
      ],
    );
  }
}

class _MetricGrid extends ConsumerWidget {
  const _MetricGrid({required this.current, required this.palette});

  final CurrentWeather current;
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(unitFormatterProvider);

    final tiles = [
      (WeatherIcons.humidity, 'Humidity', f.humidity(current.humidity)),
      (WeatherIcons.wind, 'Wind', f.wind(current.windSpeed)),
      (WeatherIcons.uv, 'UV Index', current.uvIndex.round().toString()),
      (
        WeatherIcons.visibility,
        'Visibility',
        f.visibility(current.visibilityMetres),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // A nested scroll view counts as "primary" and would otherwise inherit
      // the screen's safe-area inset as its own padding.
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      // Tuned to the tile's own content: 14px padding around an 11px caption
      // over a 16px value, both on the body's 1.55 line height.
      childAspectRatio: 2.4,
      children: [
        for (var i = 0; i < tiles.length; i++)
          MetricTile(
            icon: tiles[i].$1,
            label: tiles[i].$2,
            value: tiles[i].$3,
            palette: palette,
            delay: Duration(milliseconds: 60 * i),
          ),
      ],
    );
  }
}
