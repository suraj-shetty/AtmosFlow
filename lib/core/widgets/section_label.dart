import 'package:flutter/material.dart';

import '../theme/atmos_tokens.dart';

/// The uppercase kicker above every list — the design system's `h6`:
/// 11px, `letter-spacing: .08em`, neutral-700.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        height: 1.4,
        letterSpacing: 0.08 * 11,
        color: color ?? context.tokens.neutral.s700,
      ),
    );
  }
}
