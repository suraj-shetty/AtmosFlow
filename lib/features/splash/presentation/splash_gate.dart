import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/atmos_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../weather/application/weather_providers.dart';
import 'brand_mark.dart';

/// The first two seconds, as the brand design lays them out.
///
/// It sits over the router rather than in front of it as a route, because the
/// design asks for one continuous picture: "the gradient never resets — it
/// just becomes today". Home is already built and laid out underneath while
/// the splash is still on screen, so the handoff is a cross-dissolve between
/// two skies rather than a screen swap.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Motion.splashDwell,
  )..forward();

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: Motion.splashHandoff,
  );

  /// The idle motion of the sky, on its own clock — it has to keep going for
  /// as long as the splash is up, however long the forecast takes.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: Motion.splashIdle,
  );

  Timer? _idleStart;
  Timer? _patience;
  bool _slow = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    // "0ms static image · 180ms sky animates in" — the first frames match the
    // OS launch image exactly, so the seam between them is invisible.
    _idleStart = Timer(Motion.splashSkyIn, () {
      if (mounted) _idle.repeat();
    });
    _patience = Timer(Motion.splashPatience, () {
      if (mounted) setState(() => _slow = true);
    });
    // Two things can finish last: the dwell and the forecast. A provider
    // change rebuilds this widget on its own, so only the dwell needs saying.
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _gone = true);
      }
    });
  }

  @override
  void dispose() {
    _idleStart?.cancel();
    _patience?.cancel();
    _intro.dispose();
    _exit.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// True once there is nothing left to wait for: either a forecast has
  /// resolved, or there is no place saved and the app is going to onboarding,
  /// where there is nothing to resolve.
  bool get _ready {
    final place = ref.watch(selectedPlaceProvider);
    if (place == null) return true;
    final forecast = ref.watch(currentForecastProvider);
    return forecast != null && !forecast.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;

    if (_ready && _intro.isCompleted && _exit.isDismissed) {
      // Deferred by a frame because this is decided during build, and
      // starting a controller mid-build would rebuild what is already
      // building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _exit.isDismissed) _exit.forward();
      });
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          // Home is laid out and live underneath; nothing aimed at the splash
          // should reach it by accident.
          child: AbsorbPointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(_exit),
              child: _Splash(intro: _intro, idle: _idle, slow: _slow),
            ),
          ),
        ),
      ],
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.intro, required this.idle, required this.slow});

  final Animation<double> intro;
  final Animation<double> idle;
  final bool slow;

  @override
  Widget build(BuildContext context) {
    // The OS picked the launch image by its own light/dark setting, so the
    // Flutter splash has to agree with it or the handoff flashes. The design
    // asks for the night sky "between sunset and sunrise"; the platform's
    // appearance is the only reading of that available before any forecast.
    final night = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);
    final drift = still ? null : idle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angle: Brand.splashAngle,
              colors: night ? Brand.nightSky : Brand.splashSky,
              stops: night ? Brand.nightSkyStops : Brand.splashSkyStops,
              size: size,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!night) ..._weather(size, drift),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 22,
                  children: [
                    BrandMark(night: night, drift: drift),
                    _Wordmark(intro: intro, night: night, still: still),
                  ],
                ),
              ),
              if (slow)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 34,
                  child: Center(child: _Patience(night: night)),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The sky's own weather: one high sun and one band of cloud drifting in
  /// from the left edge. Never a spinner — the sky is the loading state.
  List<Widget> _weather(Size size, Animation<double>? drift) {
    final glow = Positioned(
      left: size.width / 2 - 150,
      top: size.height * 0.38 - 150,
      width: 300,
      height: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: cssRadialGradient(
            centreX: 0.5,
            centreY: 0.5,
            colors: const [Color(0x99FFEEBE), Color(0x00FFEEBE)],
            stops: const [0.0, 0.66],
          ),
        ),
      ),
    );

    final band = Positioned(
      left: -50,
      top: 70,
      width: 150,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );

    if (drift == null) return [glow, band];
    return [
      AnimatedBuilder(
        animation: drift,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.06 * (1 - (2 * drift.value - 1).abs()),
          child: child,
        ),
        child: Stack(fit: StackFit.expand, children: [glow]),
      ),
      AnimatedBuilder(
        animation: drift,
        builder: (context, child) => Transform.translate(
          offset: Offset(-3 + 7 * (1 - (2 * drift.value - 1).abs()), 0),
          child: child,
        ),
        child: Stack(fit: StackFit.expand, children: [band]),
      ),
    ];
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.intro,
    required this.night,
    required this.still,
  });

  final Animation<double> intro;
  final bool night;
  final bool still;

  @override
  Widget build(BuildContext context) {
    // The night sky is far too dark for the design's ink, and the brand file
    // does not name a colour for it; the moon's cream is the one light the
    // night mark already uses.
    final ink = night ? Brand.moon : Brand.ink;
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 7,
      children: [
        Text(
          'AtmosFlow',
          style: TextStyle(
            fontFamily: AtmosTokens.fontHeading,
            fontSize: 29,
            height: 1,
            letterSpacing: -0.01 * 29,
            color: ink,
          ),
        ),
        Text(
          'Your sky, beautifully forecasted',
          style: TextStyle(
            fontFamily: AtmosTokens.fontBody,
            fontSize: 12,
            height: 1,
            letterSpacing: 0.02 * 12,
            color: ink.withValues(alpha: 0.66),
          ),
        ),
      ],
    );

    if (still) return block;

    // `@keyframes afRise` — up 16px into place, between 260ms and 600ms.
    final rise = CurvedAnimation(
      parent: intro,
      curve: Interval(
        Motion.splashRiseStart.inMilliseconds /
            Motion.splashDwell.inMilliseconds,
        Motion.splashRiseEnd.inMilliseconds / Motion.splashDwell.inMilliseconds,
        curve: Curves.easeOut,
      ),
    );
    return AnimatedBuilder(
      animation: rise,
      builder: (context, child) => Opacity(
        opacity: rise.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - rise.value)),
          child: child,
        ),
      ),
      child: block,
    );
  }
}

/// The hairline that appears only if the forecast is taking its time.
class _Patience extends StatelessWidget {
  const _Patience({required this.night});

  final bool night;

  @override
  Widget build(BuildContext context) {
    final ink = night ? Brand.moon : Brand.ink;
    return Container(
      width: 44,
      height: 3,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        widthFactor: 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
