import 'package:flutter/material.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/widgets/screen_transition.dart';

/// One cell of Home's 2×2 metric grid — icon, caption, value — on light
/// glass, rising into place with the staggered `fadeSlideUp`.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;
  final String value;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return FadeSlideUp(
      delay: delay,
      child: GlassSurface(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tokens.accent2Ramp.s700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: tokens.neutral.s600),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, color: tokens.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
