import 'dart:math' as math;

import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/core/theme/atmos_tokens.dart';
import 'package:atmos_flow/core/theme/weather_palette.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home's cards take their glass and their copy from the sky. The failure
/// mode is silent — ink text on a night sky still lays out perfectly, it is
/// just unreadable — so these measure the contrast rather than the colours.
void main() {
  final tokens = AppTheme.light().extension<AtmosTokens>()!;

  /// The glass recipes: white at .42 over a light sky, .08 over a dark one.
  Color cardBackground(WeatherPalette p) {
    // Mid stop — the gradient's own middle, and where most cards sit.
    final sky = p.gradient.colors[1];
    return Color.alphaBlend(
      Colors.white.withValues(alpha: p.cardIsDark ? 0.08 : 0.42),
      sky,
    );
  }

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  for (final condition in WeatherCondition.values) {
    for (final isNight in [false, true]) {
      final name = '${condition.name}${isNight ? ' at night' : ' by day'}';

      test('$name keeps its card copy legible', () {
        final palette = WeatherPalette.resolve(
          tokens,
          condition,
          isNight: isNight,
        );
        final background = cardBackground(palette);

        // Values and day names carry the reading — hold them to AA body text.
        expect(
          contrast(palette.cardText, background),
          greaterThanOrEqualTo(4.5),
          reason: '$name: card value text on ${background.toARGB32()}',
        );

        // Captions and the icon roles are secondary, but still have to be
        // seen. AA large-text is the floor.
        for (final (role, colour) in [
          ('caption', palette.cardSubText),
          ('accent icon', palette.cardAccent),
          ('sage icon', palette.cardAccent2),
        ]) {
          expect(
            contrast(colour, background),
            greaterThanOrEqualTo(3.0),
            reason: '$name: $role on ${background.toARGB32()}',
          );
        }
      });

      test('$name keeps its copy legible on the bare sky', () {
        final palette = WeatherPalette.resolve(
          tokens,
          condition,
          isNight: isNight,
        );
        final stops = palette.gradient.colors;

        // The hero and the header own the top of the screen.
        expect(
          contrast(palette.text, stops.first),
          greaterThanOrEqualTo(4.5),
          reason: '$name: hero on the top stop',
        );
        expect(
          contrast(palette.accentText, stops.first),
          greaterThanOrEqualTo(3.0),
          reason: '$name: place name on the top stop',
        );

        // Section kickers sit below the hero, so they answer to the mid and
        // bottom stops rather than the top one.
        for (final stop in stops.sublist(1)) {
          expect(
            contrast(palette.kickerText, stop),
            greaterThanOrEqualTo(3.0),
            reason: '$name: kicker on gradient stop ${stop.toARGB32()}',
          );
        }
      });
    }
  }
}
