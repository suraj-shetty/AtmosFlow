import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure/app_failure.dart';
import '../../../core/theme/atmos_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/weather_palette.dart';
import '../../../routing/app_router.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/domain/weather_condition.dart';
import '../../weather/presentation/ambient/ambient_sky.dart';
import '../../weather/presentation/ambient/sun_layer.dart';

/// The first screen: the app's name over a sky that cycles through five moods,
/// with the two ways in — grant location, or pick a city by hand.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Timer? _timer;
  int _moodIndex = 0;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Motion.moodDwell, (_) {
      if (!mounted) return;
      setState(() => _moodIndex = (_moodIndex + 1) % 5);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _enableLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final place = await ref.resolveDeviceLocation();
      ref.read(savedLocationsProvider.notifier).add(place);
      ref.read(selectedPlaceProvider.notifier).select(place);
      if (!mounted) return;
      context.go(Routes.home);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _locating = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          action: SnackBarAction(
            label: 'Search',
            onPressed: () => context.go(Routes.search),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final moods = OnboardingMood.all(tokens);
    final mood = moods[_moodIndex];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: AnimatedContainer(
        duration: Motion.moodCrossFade,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: mood.gradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: _MoodAmbient(mood: mood, enabled: !reduceMotion),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 14,
                          children: [
                            Text(
                              'AtmosFlow',
                              style: TextStyle(
                                fontFamily: AtmosTokens.fontHeading,
                                fontSize: 46,
                                height: 1.12,
                                letterSpacing: -0.01 * 46,
                                color: mood.text,
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Text(
                                'Your sky, beautifully forecasted.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: mood.text.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: GlassSurface(
                      dark: mood.darkCard,
                      // GLASS_LIGHT pads 14, GLASS_DARK pads 16.
                      padding: EdgeInsets.all(mood.darkCard ? 16 : 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _locating ? null : _enableLocation,
                            child: Text(
                              _locating ? 'Locating…' : 'Enable Location',
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(Routes.search),
                            child: const Text('Enter Location Manually'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding's sky differs from Home's: the sun is larger, centred and shows
/// its disc, and everything sits a little lower on the screen.
class _MoodAmbient extends StatelessWidget {
  const _MoodAmbient({required this.mood, required this.enabled});

  final OnboardingMood mood;

  /// False holds the mood's sky still, the way Home does — the carousel is
  /// the point of this screen, so an empty gradient would be no onboarding
  /// at all.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: enabled,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: Motion.moodCrossFade,
          child: KeyedSubtree(
            key: ValueKey('${mood.condition}-${mood.isNight}'),
            child: Stack(
              children: [
                if (mood.condition == WeatherCondition.clear && !mood.isNight)
                  const SunLayer(
                    size: 180,
                    top: 70,
                    glowInset: 30,
                    spin: Duration(seconds: 90),
                  )
                else
                  Positioned.fill(
                    child: AmbientSky(
                      condition: mood.condition,
                      isNight: mood.isNight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
