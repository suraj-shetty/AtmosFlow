import 'package:flutter/material.dart';

import '../theme/atmos_tokens.dart';

/// The design system's `.seg` / `.seg-opt` — a pill-bordered row of options
/// where the selected one fills with the accent.
///
/// Rendered on the dark Settings glass, so the border and unselected text take
/// their colour from [foregroundColor].
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.foregroundColor,
    required this.borderColor,
    required this.labelOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color foregroundColor;
  final Color borderColor;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: _Option(
                  label: labelOf(options[i]),
                  selected: options[i] == selected,
                  onTap: () => onChanged(options[i]),
                  foregroundColor: foregroundColor,
                  accent: tokens.accent,
                  onAccent: tokens.bg,
                  leftBorder: i == 0 ? null : borderColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.foregroundColor,
    required this.accent,
    required this.onAccent,
    required this.leftBorder,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color accent;
  final Color onAccent;
  final Color? leftBorder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: leftBorder == null
              ? null
              : Border(left: BorderSide(color: leftBorder!)),
        ),
        child: Material(
          color: selected ? accent : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? onAccent : foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
