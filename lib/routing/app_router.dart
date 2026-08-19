import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/search/presentation/saved_locations_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/weather/application/weather_providers.dart';
import '../features/weather/presentation/day_detail/day_detail_screen.dart';
import '../features/weather/presentation/home/home_screen.dart';
import 'app_shell.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const search = '/search';
  static const settings = '/settings';
  static const savedLocations = '/search/saved';

  /// Day detail is addressed by the day's index in the 7-day list, which is
  /// stable for as long as the forecast the user is looking at.
  static String day(int index) => '/home/day/$index';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.onboarding,
    redirect: (context, state) {
      final hasPlace = ref.read(selectedPlaceProvider) != null;
      final location = state.matchedLocation;

      // Search stays reachable before a place is chosen — it is the other half
      // of onboarding ("Enter Location Manually"), and blocking it would trap
      // a user who declines location access.
      const reachableWithoutPlace = [
        Routes.onboarding,
        Routes.search,
        Routes.savedLocations,
      ];

      if (!hasPlace && !reachableWithoutPlace.contains(location)) {
        return Routes.onboarding;
      }
      if (hasPlace && location == Routes.onboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'day/:index',
                    builder: (context, state) => DayDetailScreen(
                      dayIndex:
                          int.tryParse(state.pathParameters['index'] ?? '') ??
                          0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (context, state) => const SearchScreen(),
                routes: [
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => const SavedLocationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
