import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/atmos_tokens.dart';
import '../../../../core/theme/motion.dart';

/// The sun: a pulsing radial glow under four rays on a very slow spin.
///
/// Home draws the glow and rays only; onboarding adds a solid disc, which is
/// what [showDisc] switches on.
class SunLayer extends StatefulWidget {
  const SunLayer({
    super.key,
    this.size = 220,
    this.top = 10,
    this.showDisc = false,
    this.spin = Motion.sunRaySpin,
    this.parallax = 0,
  });

  final double size;
  final double top;
  final bool showDisc;
  final Duration spin;
  final double parallax;

  @override
  State<SunLayer> createState() => _SunLayerState();
}

class _SunLayerState extends State<SunLayer> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: widget.spin,
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.sunGlowPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inset = widget.size * (widget.showDisc ? 1 / 6 : 40 / 220);

    return Positioned(
      top: widget.top + widget.parallax,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // `sunGlowPulse` — opacity .55↔.85, scale 1↔1.08.
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Opacity(
                  opacity: 0.55 + 0.30 * _pulse.value,
                  child: Transform.scale(
                    scale: 1 + 0.08 * _pulse.value,
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(inset),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tokens.accentRamp.s300,
                            tokens.accentRamp.s300.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // `raySpin` — four bars on a 90–120s rotation at 50% opacity.
              RotationTransition(
                turns: _spin,
                child: Opacity(
                  opacity: 0.5,
                  child: CustomPaint(
                    size: Size.square(widget.size),
                    painter: _RayPainter(color: tokens.accentRamp.s500),
                  ),
                ),
              ),
              if (widget.showDisc)
                Container(
                  width: widget.size / 3,
                  height: widget.size / 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.accentRamp.s300,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RayPainter extends CustomPainter {
  const _RayPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const rayLength = 24.0;
    const rayWidth = 2.0;
    const edgeInset = 6.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Top, bottom, left, right — the four bars the CSS positions absolutely.
    canvas.drawRect(
      Rect.fromLTWH(cx - rayWidth / 2, edgeInset, rayWidth, rayLength),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cx - rayWidth / 2,
        size.height - edgeInset - rayLength,
        rayWidth,
        rayLength,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(edgeInset, cy - rayWidth / 2, rayLength, rayWidth),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - edgeInset - rayLength,
        cy - rayWidth / 2,
        rayLength,
        rayWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RayPainter old) => old.color != color;
}
