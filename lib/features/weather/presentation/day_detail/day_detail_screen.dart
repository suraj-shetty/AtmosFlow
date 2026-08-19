import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/atmos_tokens.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/theme/weather_icons.dart';
import '../../../../core/theme/weather_palette.dart';
import '../../../../core/widgets/screen_transition.dart';
import '../../../../routing/app_router.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/weather_providers.dart';
import '../../domain/forecast.dart';
import 'widgets/sun_path.dart';
import 'widgets/temperature_chart.dart';

/// One day in depth: the temperature curve, the sun's path, and four detail
/// cards. Keeps the sky palette of the current conditions.
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dayIndex});

  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentForecastProvider);
    final forecast = async?.value;
    if (forecast == null || dayIndex >= forecast.daily.length) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final day = forecast.daily[dayIndex];
    final current = forecast.current;
    final palette = WeatherPalette.resolve(
      tokens,
      current.condition,
      isNight: current.isNight,
    );
    final f = ref.watch(unitFormatterProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.gradient),
      child: ScreenTransition(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 32),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    GlassIconButton(
                      icon: WeatherIcons.chevronLeft,
                      onPressed: () => dismissPresented(context),
                      color: palette.text,
                      size: 36,
                      dark: palette.isDark,
                      tooltip: 'Back to forecast',
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMM d').format(day.date),
                        style: TextStyle(
                          fontFamily: AtmosTokens.fontHeading,
                          fontSize: 18,
                          height: 1.12,
                          letterSpacing: -0.015 * 18,
                          color: palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
                _Panel(
                  dark: palette.isDark,
                  child: TemperatureChart(
                    temperatures: day.hourlyTemperatures,
                    subLabelColor: palette.subText,
                    animate: !reduceMotion,
                  ),
                ),
                _Panel(
                  dark: palette.isDark,
                  child: SunPath(
                    sunrise: day.sunrise,
                    sunset: day.sunset,
                    progress: day.sunProgressAt(
                      dayIndex == 0 ? forecast.localNow : day.sunset,
                    ),
                    textColor: palette.text,
                    subColor: palette.subText,
                    trackColor: tokens.accentRamp.s200,
                    arcColor: tokens.accentRamp.s500,
                    animate: !reduceMotion,
                  ),
                ),
                _DetailGrid(
                  current: current,
                  day: day,
                  palette: palette,
                  humidity: f.humidity(current.humidity),
                  wind: f.wind(current.windSpeed),
                  pressure: f.pressure(current.pressureHpa),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.dark});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      dark: dark,
      padding: const EdgeInsets.all(AtmosTokens.space4),
      child: child,
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({
    required this.current,
    required this.day,
    required this.palette,
    required this.humidity,
    required this.wind,
    required this.pressure,
  });

  final CurrentWeather current;
  final DailyForecast day;
  final WeatherPalette palette;
  final String humidity;
  final String wind;
  final String pressure;

  @override
  Widget build(BuildContext context) {
    final iconColor = context.tokens.accent2Ramp.s500;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // A nested scroll view counts as "primary" and would otherwise inherit
      // the screen's safe-area inset as its own padding.
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _DetailCard(
          dark: palette.isDark,
          icon: Icon(WeatherIcons.humidity, size: 20, color: iconColor),
          label: 'Humidity',
          value: humidity,
          palette: palette,
        ),
        _DetailCard(
          dark: palette.isDark,
          // The arrow points the way the wind is going.
          icon: Transform.rotate(
            angle: (current.windDirection + 180) * math.pi / 180,
            child: Icon(WeatherIcons.windArrow, size: 20, color: iconColor),
          ),
          label: 'Wind · ${current.windCompass}',
          value: wind,
          palette: palette,
        ),
        _DetailCard(
          dark: palette.isDark,
          icon: Icon(WeatherIcons.uv, size: 20, color: iconColor),
          label: 'UV Index',
          value: '${day.uvIndexMax.round()} · ${uvBandOf(day.uvIndexMax)}',
          palette: palette,
          bar: uvFractionOf(day.uvIndexMax),
        ),
        _DetailCard(
          dark: palette.isDark,
          icon: Icon(WeatherIcons.pressure, size: 20, color: iconColor),
          label: 'Pressure',
          value: pressure,
          palette: palette,
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.dark,
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    this.bar,
  });

  final bool dark;
  final Widget icon;
  final String label;
  final String value;
  final WeatherPalette palette;

  /// 0–1 fill for the UV card's gradient bar.
  final double? bar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GlassSurface(
      dark: dark,
      padding: const EdgeInsets.all(AtmosTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          icon,
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.subText),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: palette.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (bar != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
              child: SizedBox(
                height: 6,
                child: ColoredBox(
                  color: palette.subText.withValues(alpha: 0.22),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: bar,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tokens.accent2Ramp.s400,
                            tokens.accentRamp.s600,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
