import 'package:atmos_flow/core/theme/atmos_tokens.dart';
import 'package:atmos_flow/core/theme/weather_palette.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokens = AtmosTokens.organic();

  group('WeatherPalette', () {
    test('every condition resolves for both day and night', () {
      for (final condition in WeatherCondition.values) {
        for (final isNight in [false, true]) {
          final palette = WeatherPalette.resolve(
            tokens,
            condition,
            isNight: isNight,
          );
          expect(palette.gradient.colors, hasLength(3));
          expect(palette.gradient.stops, [0, anything, 1]);
        }
      }
    });

    test('night is always dark, and rain and storm are dark by day too', () {
      for (final condition in WeatherCondition.values) {
        expect(
          WeatherPalette.resolve(tokens, condition, isNight: true).isDark,
          isTrue,
          reason: '${condition.name} at night should be dark',
        );
      }
      expect(
        WeatherPalette.resolve(
          tokens,
          WeatherCondition.rain,
          isNight: false,
        ).isDark,
        isTrue,
      );
      expect(
        WeatherPalette.resolve(
          tokens,
          WeatherCondition.storm,
          isNight: false,
        ).isDark,
        isTrue,
      );
      expect(
        WeatherPalette.resolve(
          tokens,
          WeatherCondition.clear,
          isNight: false,
        ).isDark,
        isFalse,
      );
    });

    test('only dark skies carry the hero text shadow', () {
      final clearDay = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: false,
      );
      final clearNight = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: true,
      );
      expect(clearDay.heroTextShadow, isEmpty);
      expect(clearNight.heroTextShadow, isNotEmpty);
    });

    test('the onboarding carousel has five moods', () {
      final moods = OnboardingMood.all(tokens);
      expect(moods, hasLength(5));
      expect(moods.last.isNight, isTrue);
      expect(moods.first.darkCard, isFalse);
      expect(moods.last.darkCard, isTrue);
    });
  });

  group('AtmosTokens', () {
    test('ramps are indexable by their CSS step', () {
      expect(tokens.accentRamp[500], const Color(0xFFD67F48));
      expect(tokens.neutral[900], const Color(0xFF2E2B25));
      expect(tokens.accent2Ramp[100], const Color(0xFFF0FAE1));
      expect(() => tokens.neutral[450], throwsArgumentError);
    });

    test('lerp interpolates the whole system', () {
      final other = tokens.copyWith(bg: const Color(0xFF000000));
      final mid = tokens.lerp(other, 1);
      expect(mid.bg, const Color(0xFF000000));
    });
  });
}
