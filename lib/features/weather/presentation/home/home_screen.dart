import 'package:flutter/material.dart';
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

  /// Drives the refresh puck. The pull gesture and the design's tap targets
  /// both set it, so there is only ever one indicator on screen.
  bool _refreshing = false;

  @override
  void dispose() {
    _scrollOffset.dispose();
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
    setState(() => _refreshing = true);
    ref.invalidate(forecastProvider(forecast.place));
    try {
      await Future.wait([
        ref.read(forecastProvider(forecast.place).future),
        // The design holds the refreshing state for a beat so the puck's spin
        // reads even when the network is instant.
        Future<void>.delayed(Motion.refreshMinimum),
      ]);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(currentForecastProvider);
    if (async == null) return const SizedBox.shrink();

    return async.when(
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

    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: AmbientSky(
              condition: current.condition,
              isNight: current.isNight,
              scrollOffset: _scrollOffset,
              enabled: !reduceMotion,
            ),
          ),
          Positioned.fill(
            child: ScreenTransition(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                // The gesture is the platform's; the indicator is the
                // design's, so the stock spinner is drawn in nothing at all.
                child: RefreshIndicator(
                  onRefresh: () => _refresh(forecast),
                  edgeOffset: 72,
                  elevation: 0,
                  color: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 72, bottom: 104),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                onSearch: () => context.push(Routes.search),
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
                              child: HourlyStrip(
                                hours: forecast.next24Hours,
                              ),
                            ),
                            _Section(
                              label: '7-day forecast',
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
                                      onTap: () => context.push(Routes.day(i)),
                                    ),
                                ],
                              ),
                            ),
                            _MetricGrid(current: current),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          RefreshPuck(
            refreshing: _refreshing,
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
            Icon(
              conditionIcon,
              size: 22,
              color: palette.text,
            ),
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
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SectionLabel(label),
        child,
      ],
    );
  }
}

class _MetricGrid extends ConsumerWidget {
  const _MetricGrid({required this.current});

  final CurrentWeather current;

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
            delay: Duration(milliseconds: 60 * i),
          ),
      ],
    );
  }
}
