import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/atmos_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/weather_icons.dart';
import '../../../core/widgets/screen_transition.dart';
import '../../../routing/app_router.dart';
import '../../weather/application/weather_providers.dart';
import 'widgets/location_row.dart';

/// The full saved list, reorderable by drag and deletable per row.
class SavedLocationsScreen extends ConsumerWidget {
  const SavedLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final places = ref.watch(savedLocationsProvider);
    final notifier = ref.read(savedLocationsProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.accentRamp.s100, tokens.bg, tokens.bg],
          stops: const [0, 0.6, 1],
        ),
      ),
      child: ScreenTransition(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 16),
              child: Row(
                spacing: 10,
                children: [
                  GlassIconButton(
                    icon: WeatherIcons.chevronLeft,
                    onPressed: () => dismissPresented(context),
                    color: tokens.text,
                    size: 36,
                    tooltip: 'Back to search',
                  ),
                  Text(
                    'Saved Locations',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: places.length,
                onReorderItem: notifier.reorder,
                proxyDecorator: (child, index, animation) =>
                    Material(color: Colors.transparent, child: child),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Padding(
                    key: ValueKey(place.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LocationRow(
                      place: place,
                      onTap: () {
                        ref.read(selectedPlaceProvider.notifier).select(place);
                        context.go(Routes.home);
                      },
                      onDelete: () => notifier.remove(place.id),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          WeatherIcons.grip,
                          size: 16,
                          color: tokens.neutral.s400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
