import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/motion.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/search/presentation/saved_locations_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/weather/application/weather_providers.dart';
import '../features/weather/presentation/day_detail/day_detail_screen.dart';
import '../features/weather/presentation/home/home_screen.dart';

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
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _fade(state, const HomeScreen()),
        routes: [
          GoRoute(
            path: 'day/:index',
            pageBuilder: (context, state) => _fade(
              state,
              DayDetailScreen(
                dayIndex: int.tryParse(state.pathParameters['index'] ?? '') ?? 0,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.search,
        pageBuilder: (context, state) => _modal(state, const SearchScreen()),
        routes: [
          GoRoute(
            path: 'saved',
            pageBuilder: (context, state) =>
                _modal(state, const SavedLocationsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) =>
            _modal(state, const SettingsScreen()),
      ),
    ],
  );
});

/// Closes a presented screen, dropping it back out of the bottom edge.
///
/// Search is also reachable straight from onboarding, where there is no
/// forecast underneath to return to — hence the fallback.
void dismissPresented(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.home);
  }
}

/// Search and Settings arrive the way an iOS full-screen cover does: the
/// whole screen rises from the bottom edge and drops back out of it. Their
/// bodies still play the design's own fade-and-lift on top, but the gradient
/// rides the slide, so the panel reads as one surface moving.
CustomTransitionPage<void> _modal(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: Motion.modalPresent,
    reverseTransitionDuration: Motion.modalDismiss,
    child: Scaffold(body: child),
    transitionsBuilder: (context, animation, secondary, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Motion.modalPresentCurve,
            reverseCurve: Motion.modalDismissCurve,
          ),
        ),
        child: child,
      );
    },
  );
}

/// The design has no page-level transition of its own: every screen body
/// fades and lifts itself in through `ScreenTransition`, so the route swap
/// underneath has to be instant or the two would stack.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    child: Scaffold(body: child),
    transitionsBuilder: (context, animation, secondary, child) => child,
  );
}
