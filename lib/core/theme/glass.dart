import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'atmos_tokens.dart';

/// The two glass recipes the design uses everywhere, from `GLASS_LIGHT` and
/// `GLASS_DARK` in the prototype:
///
/// * light — `rgba(255,255,255,.42)`, `blur(18px) saturate(160%)`,
///   `1px solid rgba(255,255,255,.55)`, `--shadow-sm`
/// * dark — `rgba(255,255,255,.08)`, `blur(14px)`,
///   `1px solid rgba(255,255,255,.16)`, `--shadow-lg`
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.dark = false,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.margin,
    this.width,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Picks the recipe from the sky it sits on.
  factory GlassSurface.forSky({
    Key? key,
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    double? width,
  }) {
    return GlassSurface(
      key: key,
      dark: isDark,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      margin: margin,
      width: width,
      child: child,
    );
  }

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final Clip clipBehavior;

  static const double _lightBlur = 18;
  static const double _darkBlur = 14;
  static const double _lightSaturation = 1.6;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AtmosTokens.radiusLg);
    final resolvedPadding =
        padding ??
        EdgeInsets.all(dark ? AtmosTokens.space4 : AtmosTokens.space3);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.08 : 0.42),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
          width: 1,
        ),
        borderRadius: radius,
      ),
      child: Padding(padding: resolvedPadding, child: child),
    );

    if (onTap != null) {
      surface = Stack(
        children: [
          surface,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }

    Widget result = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: glassFilter(dark: dark),
        child: surface,
      ),
    );

    result = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark ? AtmosTokens.shadowLg : AtmosTokens.shadowSm,
      ),
      child: result,
    );

    if (width != null) result = SizedBox(width: width, child: result);
    if (margin != null) result = Padding(padding: margin!, child: result);
    return result;
  }

  /// `backdrop-filter: blur(Npx) saturate(160%)`. The saturation only applies
  /// to the light recipe, matching the CSS.
  static ui.ImageFilter glassFilter({required bool dark}) {
    final blur = ui.ImageFilter.blur(
      sigmaX: dark ? _darkBlur / 2 : _lightBlur / 2,
      sigmaY: dark ? _darkBlur / 2 : _lightBlur / 2,
    );
    if (dark) return blur;
    return ui.ImageFilter.compose(
      outer: ui.ColorFilter.matrix(_saturationMatrix(_lightSaturation)),
      inner: blur,
    );
  }

  /// CSS `saturate()` as a 4×5 colour matrix, using the same luminance
  /// coefficients the filter spec defines.
  static List<double> _saturationMatrix(double s) {
    const lr = 0.213, lg = 0.715, lb = 0.072;
    return [
      lr + (1 - lr) * s, lg - lg * s, lb - lb * s, 0, 0, //
      lr - lr * s, lg + (1 - lg) * s, lb - lb * s, 0, 0, //
      lr - lr * s, lg - lg * s, lb + (1 - lb) * s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// The pill-shaped glass button used for the search and back affordances —
/// `rgba(255,255,255,.5)` with a `.6` border, 36–38px circle.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.size = 38,
    this.iconSize = 18,
    this.dark = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double iconSize;
  final bool dark;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: GlassSurface.glassFilter(dark: dark),
        child: Material(
          color: Colors.white.withValues(alpha: dark ? 0.14 : 0.5),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: dark ? 0.2 : 0.6),
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
