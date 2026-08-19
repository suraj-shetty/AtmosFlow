import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/atmos_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/weather_icons.dart';
import '../../../core/widgets/screen_transition.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../routing/app_router.dart';
import '../../weather/application/weather_providers.dart';
import '../application/settings_providers.dart';
import '../application/unit_formatter.dart';
import '../domain/app_settings.dart';

/// Units, appearance and location management, on the design's one always-dark
/// screen (`accent-800 → neutral-900`).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Color _onDark = Color(0xFFF9F4ED);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final borderColor = Colors.white.withValues(alpha: 0.25);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.accentRamp.s800, tokens.neutral.s900],
        ),
      ),
      child: ScreenTransition(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 32),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    GlassIconButton(
                      icon: WeatherIcons.chevronLeft,
                      onPressed: () => dismissPresented(context),
                      color: _onDark,
                      size: 36,
                      dark: true,
                      tooltip: 'Back to forecast',
                    ),
                    Text(
                      'Settings',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: _onDark),
                    ),
                  ],
                ),
                _Card(
                  label: 'Units',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Temperature',
                          style: TextStyle(fontSize: 14, color: _onDark),
                        ),
                        _FlippingTemperature(unit: settings.temperatureUnit),
                      ],
                    ),
                    SegmentedControl<TemperatureUnit>(
                      options: TemperatureUnit.values,
                      selected: settings.temperatureUnit,
                      onChanged: notifier.setTemperatureUnit,
                      foregroundColor: _onDark,
                      borderColor: borderColor,
                      labelOf: (u) => u.label,
                    ),
                    const Text(
                      'Wind Speed',
                      style: TextStyle(fontSize: 14, color: _onDark),
                    ),
                    SegmentedControl<WindUnit>(
                      options: WindUnit.values,
                      selected: settings.windUnit,
                      onChanged: notifier.setWindUnit,
                      foregroundColor: _onDark,
                      borderColor: borderColor,
                      labelOf: (u) => u.label,
                    ),
                  ],
                ),
                _Card(
                  label: 'Appearance',
                  children: [
                    SegmentedControl<AppearanceMode>(
                      options: AppearanceMode.values,
                      selected: settings.appearance,
                      onChanged: notifier.setAppearance,
                      foregroundColor: _onDark,
                      borderColor: borderColor,
                      labelOf: (m) => m.label,
                    ),
                  ],
                ),
                const _ManageLocationsCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      dark: true,
      padding: const EdgeInsets.all(AtmosTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SectionLabel(
            label,
            color: SettingsScreen._onDark.withValues(alpha: 0.7),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// The live temperature chip that flips on its Y axis whenever the unit
/// changes — the design's `@keyframes flipY`.
class _FlippingTemperature extends StatefulWidget {
  const _FlippingTemperature({required this.unit});

  final TemperatureUnit unit;

  @override
  State<_FlippingTemperature> createState() => _FlippingTemperatureState();
}

class _FlippingTemperatureState extends State<_FlippingTemperature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.unitFlip,
  );

  /// The keyframes turn the chip 0 → 94° → 0, so its face is edge-on — and a
  /// swap invisible — the moment the rotation passes 90°.
  static const double _peakDegrees = 94;
  static const double _swapAt = (90 / _peakDegrees) / 2;

  /// A fixed 22°C sample, so the chip demonstrates the unit rather than
  /// reporting the weather.
  static const double _sampleCelsius = 22;

  /// The label the chip carries into the flip, held until the rotation hides
  /// its face. Without it the value changes on the first frame, while the chip
  /// is still square to the viewer, and the flip reads as a delayed reaction
  /// to a change the user has already seen.
  String? _outgoing;

  static String _labelFor(TemperatureUnit unit) =>
      UnitFormatter(
        AppSettings(temperatureUnit: unit),
      ).temperature(_sampleCelsius);

  @override
  void didUpdateWidget(_FlippingTemperature old) {
    super.didUpdateWidget(old);
    if (old.unit == widget.unit) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // No flip to hide the swap behind, so show the new value at once.
      _outgoing = null;
      _controller.value = 1;
      return;
    }
    _outgoing = _labelFor(old.unit);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _labelFor(widget.unit);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final turn = t <= 0.5 ? t * 2 : (1 - t) * 2;
        final label = t < _swapAt ? (_outgoing ?? incoming) : incoming;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0025)
            ..rotateY(turn * _peakDegrees * math.pi / 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AtmosTokens.fontHeading,
                fontSize: 20,
                color: SettingsScreen._onDark,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ManageLocationsCard extends ConsumerWidget {
  const _ManageLocationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(savedLocationsProvider);
    final notifier = ref.read(savedLocationsProvider.notifier);
    final formatter = ref.watch(unitFormatterProvider);

    return _Card(
      label: 'Manage Locations',
      children: [
        if (places.isEmpty)
          Text(
            'No saved locations yet.',
            style: TextStyle(
              fontSize: 14,
              color: SettingsScreen._onDark.withValues(alpha: 0.7),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: places.length,
            onReorder: notifier.reorder,
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, index) {
              final place = places[index];
              final temp = ref
                  .watch(forecastProvider(place))
                  .value
                  ?.current
                  .temperature;

              return Padding(
                key: ValueKey(place.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AtmosTokens.radiusMd),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          WeatherIcons.grip,
                          size: 16,
                          color: SettingsScreen._onDark.withValues(alpha: 0.6),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          place.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: SettingsScreen._onDark,
                          ),
                        ),
                      ),
                      if (temp != null)
                        Text(
                          formatter.temperature(temp),
                          style: TextStyle(
                            fontSize: 13,
                            color: SettingsScreen._onDark.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () => notifier.remove(place.id),
                        icon: Icon(
                          WeatherIcons.delete,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Remove ${place.name}',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
