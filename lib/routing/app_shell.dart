import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/atmos_tokens.dart';
import '../core/theme/glass.dart';
import '../core/theme/motion.dart';
import '../core/theme/weather_icons.dart';
import '../core/theme/weather_palette.dart';
import '../features/weather/application/weather_providers.dart';
import 'app_router.dart';

/// The three tabbed branches under one floating tab bar.
///
/// The bar is a positioned overlay rather than a `BottomNavigationBar` because
/// the design floats it over the sky gradient with 16px side insets and a full
/// pill radius — and it disappears entirely on the pushed screens (Day Detail,
/// Saved Locations), exactly as `showTabBar` does in the prototype.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final atBranchRoot =
        location == Routes.home ||
        location == Routes.search ||
        location == Routes.settings;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          shell,
          if (atBranchRoot)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14 + MediaQuery.paddingOf(context).bottom * 0.4,
              child: _TabBar(
                currentIndex: shell.currentIndex,
                onTap: (index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
                dark: _chromeIsDark(ref, shell.currentIndex),
              ),
            ),
        ],
      ),
    );
  }

  /// The bar takes its light/dark treatment from whatever is behind it:
  /// Settings is always dark, Home follows its sky, Search is always light.
  static bool _chromeIsDark(WidgetRef ref, int index) {
    if (index == 2) return true; // Settings
    if (index != 0) return false; // Search
    final forecast = ref.watch(currentForecastProvider)?.value;
    if (forecast == null) return false;
    return WeatherPalette.resolve(
      AtmosTokens.organic(),
      forecast.current.condition,
      isNight: forecast.current.isNight,
    ).isDark;
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.currentIndex,
    required this.onTap,
    required this.dark,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool dark;

  static const _items = [
    (WeatherIcons.home, 'Home'),
    (WeatherIcons.search, 'Search'),
    (WeatherIcons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeColor = dark ? Colors.white : tokens.accentRamp.s700;
    final inactiveColor = dark
        ? Colors.white.withValues(alpha: 0.5)
        : tokens.neutral.s500;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AtmosTokens.radiusPill)),
        boxShadow: AtmosTokens.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
        child: BackdropFilter(
          filter: GlassSurface.glassFilter(dark: dark),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: dark ? 0.1 : 0.55),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.16 : 0.6),
              ),
              borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _TabButton(
                      icon: _items[i].$1,
                      label: _items[i].$2,
                      selected: i == currentIndex,
                      color: i == currentIndex ? activeColor : inactiveColor,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab whose icon pops to 1.22× on tap and springs back — the design's
/// `transform:scale()` on a `cubic-bezier(.34,1.56,.64,1)` transition.
class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _tapped = false;

  Future<void> _handleTap() async {
    widget.onTap();
    setState(() => _tapped = true);
    await Future<void>.delayed(Motion.tabBounceHold);
    if (mounted) setState(() => _tapped = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(AtmosTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtmosTokens.space3,
            vertical: 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _tapped ? Motion.tabBounceScale : 1,
                duration: Motion.tabBounce,
                curve: Motion.tabBounceCurve,
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: widget.color,
                  fontFamily: AtmosTokens.fontBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
