import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure/app_failure.dart';
import '../../../core/theme/atmos_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/weather_icons.dart';
import '../../../core/widgets/screen_transition.dart';
import '../../../core/widgets/section_label.dart';
import '../../../routing/app_router.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/domain/place.dart';
import 'widgets/location_row.dart';

/// Search for a city, or reach for the device's own location.
///
/// With an empty query this shows the first three saved locations; with a
/// query it shows geocoding results, or an empty state.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  /// What has been typed, held here rather than in a provider so it goes when
  /// the screen goes. A notifier rather than `setState` so the field's
  /// `onChanged` has something small to close over — see [_SearchField].
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    // Deliberately wired here, and closing over locals rather than `this`:
    // Flutter keeps the last text field's widget alive in a static, so a
    // callback handed to `TextField.onChanged` that reached back into this
    // State would hold the whole dismissed screen on the heap. Nothing the
    // field carries points anywhere near here.
    final controller = _controller;
    final query = _query;
    controller.addListener(() => query.value = controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _query.dispose();
    super.dispose();
  }

  void _select(Place place) {
    ref.read(savedLocationsProvider.notifier).add(place);
    ref.read(selectedPlaceProvider.notifier).select(place);
    context.go(Routes.home);
  }

  Future<void> _useMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final place = await ref.read(deviceLocationProvider.future);
      if (!mounted) return;
      _select(place);
    } on AppFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final saved = ref.watch(savedLocationsProvider);

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
                      color: tokens.text,
                      size: 36,
                      tooltip: 'Back to forecast',
                    ),
                    Text(
                      'Search',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                _SearchField(controller: _controller),
                GlassSurface(
                  onTap: _useMyLocation,
                  padding: const EdgeInsets.symmetric(
                    vertical: AtmosTokens.space3,
                    horizontal: AtmosTokens.space4,
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(
                        WeatherIcons.myLocation,
                        size: 16,
                        color: tokens.accentRamp.s800,
                      ),
                      Text(
                        'Use My Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.accentRamp.s800,
                        ),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _query,
                  builder: (context, query, _) => query.trim().isEmpty
                      ? _SavedSection(saved: saved, onSelect: _select)
                      : _ResultsSection(query: query, onSelect: _select),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The pill field. It carries no callbacks at all — the screen listens to the
/// controller instead, which is what keeps the dismissed screen collectable.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AtmosTokens.radiusPill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        spacing: 8,
        children: [
          Icon(WeatherIcons.search, size: 16, color: tokens.neutral.s600),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              style: TextStyle(fontSize: 14, color: tokens.text),
              cursorColor: tokens.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search for a city',
                hintStyle: TextStyle(fontSize: 14, color: tokens.neutral.s500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedSection extends StatelessWidget {
  const _SavedSection({required this.saved, required this.onSelect});

  final List<Place> saved;
  final ValueChanged<Place> onSelect;

  @override
  Widget build(BuildContext context) {
    if (saved.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AtmosTokens.space6),
        child: Text(
          'Search for a city to add your first location.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.tokens.neutral.s600),
        ),
      );
    }

    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Saved Locations'),
            GestureDetector(
              onTap: () => context.push(Routes.savedLocations),
              child: Text(
                'See all',
                style: TextStyle(fontSize: 12, color: tokens.accentRamp.s700),
              ),
            ),
          ],
        ),
        for (final place in saved.take(3))
          LocationRow(place: place, onTap: () => onSelect(place)),
      ],
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.query, required this.onSelect});

  final String query;
  final ValueChanged<Place> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final results = ref.watch(placeSearchProvider(query));

    return results.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AtmosTokens.space6),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AtmosTokens.space6),
        child: Text(
          error is AppFailure ? error.message : 'Search failed. Try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: tokens.neutral.s600),
        ),
      ),
      data: (places) {
        if (places.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 28, 12, 28),
            child: Column(
              spacing: 8,
              children: [
                Icon(WeatherIcons.search, size: 28, color: tokens.neutral.s600),
                Text(
                  'No results for "$query"',
                  style: TextStyle(fontSize: 14, color: tokens.neutral.s600),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final place in places)
              LocationRow(
                place: place,
                onTap: () => onSelect(place),
                trailing: Icon(
                  WeatherIcons.chevronRight,
                  size: 16,
                  color: tokens.neutral.s400,
                ),
              ),
          ],
        );
      },
    );
  }
}
