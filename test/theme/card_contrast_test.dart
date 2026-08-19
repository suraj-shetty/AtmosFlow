import 'package:atmos_flow/core/theme/atmos_tokens.dart';
import 'package:atmos_flow/core/theme/weather_palette.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home's chips, rows and tiles sit on glass over the sky. If they always
/// used the light recipe with ink text — as the design prototype did — the
/// text would all but vanish on the night, rain and storm gradients. These
/// tests pin the inversion.
void main() {
  final tokens = AtmosTokens.organic();

  /// Relative luminance per WCAG 2.x.
  double luminance(Color c) => c.computeLuminance();

  /// WCAG contrast ratio between two opaque colours.
  double contrast(Color a, Color b) {
    final l1 = luminance(a), l2 = luminance(b);
    final hi = l1 > l2 ? l1 : l2;
    final lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// What a card actually looks like: the glass tint composited over the
  /// middle of the sky gradient behind it.
  Color cardBackground(WeatherPalette p) {
    final sky = p.gradient.colors[1];
    final tint = Colors.white.withValues(alpha: p.cardIsDark ? 0.08 : 0.42);
    return Color.alphaBlend(tint, sky);
  }

  group('card text stays legible on every sky', () {
    for (final condition in WeatherCondition.values) {
      for (final isNight in [false, true]) {
        final name = '${condition.name}${isNight ? ' at night' : ' by day'}';

        test('$name — primary value text clears 4.5:1', () {
          final palette = WeatherPalette.resolve(
            tokens,
            condition,
            isNight: isNight,
          );
          final ratio = contrast(palette.cardText, cardBackground(palette));
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name: cardText on its card is only '
                '${ratio.toStringAsFixed(2)}:1',
          );
        });

        test('$name — captions and icons clear 3:1', () {
          final palette = WeatherPalette.resolve(
            tokens,
            condition,
            isNight: isNight,
          );
          final background = cardBackground(palette);
          // Captions carry alpha on dark skies; flatten before measuring.
          final caption = Color.alphaBlend(palette.cardSubText, background);

          expect(
            contrast(caption, background),
            greaterThanOrEqualTo(3.0),
            reason: '$name: cardSubText is too close to its card',
          );
          expect(
            contrast(palette.cardAccent, background),
            greaterThanOrEqualTo(3.0),
            reason: '$name: cardAccent is too close to its card',
          );
          expect(
            contrast(palette.cardAccent2, background),
            greaterThanOrEqualTo(3.0),
            reason: '$name: cardAccent2 is too close to its card',
          );
        });
      }
    }
  });

  skyTextTests();
  heroShadowTests();

  group('card roles invert with the sky', () {
    test('dark skies take the dark glass recipe and light text', () {
      final night = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: true,
      );
      expect(night.cardIsDark, isTrue);
      expect(luminance(night.cardText), greaterThan(0.5));
      // The light ramp step, not the deep one that vanishes on dark glass.
      expect(night.cardAccent, tokens.accentRamp.s300);
    });

    test('light skies keep ink text and the deep ramp steps', () {
      final day = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: false,
      );
      expect(day.cardIsDark, isFalse);
      expect(day.cardText, tokens.text);
      expect(day.cardAccent, tokens.accentRamp.s700);
    });

    test('the card recipe follows the glass background, not the hero', () {
      // Daytime storm is dark all the way through, so its cards invert.
      final storm = WeatherPalette.resolve(
        tokens,
        WeatherCondition.storm,
        isNight: false,
      );
      expect(storm.isDark, isTrue);
      expect(storm.cardIsDark, isTrue);

      // Daytime rain wants white hero text on its dark gradient, but its
      // mid-tone behind glass is too light for white card text — so the two
      // decisions diverge, and that is the point of keeping them separate.
      final rain = WeatherPalette.resolve(
        tokens,
        WeatherCondition.rain,
        isNight: false,
      );
      expect(rain.isDark, isTrue);
      expect(rain.cardIsDark, isFalse);
      expect(rain.cardText, tokens.text);
    });
  });
}

/// Text that sits directly on the sky gradient rather than on glass. A single
/// colour cannot serve the whole column, because the gradient changes
/// luminance with depth — daytime rain runs dark at the top and pale at the
/// bottom, which is what left the section labels washed out.
void skyTextTests() {
  final tokens = AtmosTokens.organic();

  double contrast(Color a, Color b) => WeatherPalette.contrastRatio(a, b);

  const depths = <String, double>{
    'location bar': SkyDepth.locationBar,
    'refresh hint': SkyDepth.refreshHint,
    'hero': SkyDepth.hero,
    'feels like': SkyDepth.feelsLike,
    'hourly label': SkyDepth.hourlyLabel,
    'daily label': SkyDepth.dailyLabel,
  };

  group('sky text stays legible at the depth it occupies', () {
    for (final condition in WeatherCondition.values) {
      for (final isNight in [false, true]) {
        final sky = '${condition.name}${isNight ? ' at night' : ' by day'}';

        test('$sky — every depth holds its ratio', () {
          final p = WeatherPalette.resolve(tokens, condition, isNight: isNight);

          depths.forEach((name, t) {
            final background = p.skyColorAt(t);

            // Primary copy at this depth. The hero is 96px display text —
            // WCAG "large" — so it holds 3:1; everything else holds 4.5:1.
            // A mid-tone sky like daytime rain has no flat colour that
            // reaches 4.5 in either direction, which is why the hero also
            // carries an adaptive shadow.
            final isHero = t == SkyDepth.hero;
            final primary = isHero ? p.heroText : p.onSkyAt(p.text, t);
            final primaryRatio = contrast(primary, background);
            expect(
              primaryRatio,
              greaterThanOrEqualTo(isHero ? 3.0 : 4.5),
              reason:
                  '$sky at $name: primary text is only '
                  '${primaryRatio.toStringAsFixed(2)}:1',
            );

            // Muted copy — kickers and captions — carries alpha, so flatten.
            final muted = Color.alphaBlend(p.onSkyMutedAt(t), background);
            final mutedRatio = contrast(muted, background);
            expect(
              mutedRatio,
              greaterThanOrEqualTo(3.0),
              reason:
                  '$sky at $name: muted text is only '
                  '${mutedRatio.toStringAsFixed(2)}:1',
            );
          });
        });
      }
    }
  });

  group('skyColorAt', () {
    final p = WeatherPalette.resolve(
      tokens,
      WeatherCondition.clear,
      isNight: false,
    );

    test('returns the stops at the ends', () {
      expect(p.skyColorAt(0), p.gradient.colors.first);
      expect(p.skyColorAt(1), p.gradient.colors.last);
      expect(p.skyColorAt(-1), p.gradient.colors.first);
      expect(p.skyColorAt(2), p.gradient.colors.last);
    });

    test('interpolates between them', () {
      final mid = p.gradient.stops![1];
      expect(p.skyColorAt(mid), p.gradient.colors[1]);
      // Halfway to the middle stop is neither endpoint.
      final quarter = p.skyColorAt(mid / 2);
      expect(quarter, isNot(p.gradient.colors.first));
      expect(quarter, isNot(p.gradient.colors[1]));
    });
  });

  test('a colour that already reads is left exactly as the design set it', () {
    final night = WeatherPalette.resolve(
      tokens,
      WeatherCondition.clear,
      isNight: true,
    );
    // White on a near-black sky needs no rescuing.
    expect(night.onSkyAt(night.text, SkyDepth.hero), night.text);
  });
}

/// The hero's shadow is what rescues a mid-tone sky, where no flat text
/// colour clears 4.5:1 in either direction.
void heroShadowTests() {
  final tokens = AtmosTokens.organic();

  group('hero shadow adapts to what is behind it', () {
    test('a light sky needs none', () {
      final clearDay = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: false,
      );
      expect(clearDay.heroTextShadow, isEmpty);
    });

    test('a mid-tone sky gets the strongest treatment', () {
      final rainDay = WeatherPalette.resolve(
        tokens,
        WeatherCondition.rain,
        isNight: false,
      );
      final night = WeatherPalette.resolve(
        tokens,
        WeatherCondition.clear,
        isNight: true,
      );

      expect(rainDay.heroTextShadow, hasLength(2));
      expect(night.heroTextShadow, hasLength(1));
      // Tighter and more opaque than the soft lift a dark sky gets.
      expect(
        rainDay.heroTextShadow.first.color.a,
        greaterThan(night.heroTextShadow.first.color.a),
      );
      expect(
        rainDay.heroTextShadow.first.blurRadius,
        lessThan(night.heroTextShadow.first.blurRadius),
      );
    });
  });
}
