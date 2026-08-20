import 'package:atmos_flow/core/failure/app_failure.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/search/presentation/search_screen.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../support/harness.dart';

/// Resolving the device's location is the one flow that waits on the user
/// rather than on the network: the permission dialog stays up for as long as
/// they look at it, and nothing watches the provider while it does. That gap
/// used to end in "Cannot use the Ref … after it has been disposed" instead of
/// a place.
void main() {
  late _FakeGeolocator geolocator;

  setUp(() {
    geolocator = _FakeGeolocator();
    GeolocatorPlatform.instance = geolocator;
  });

  /// Taps a button that resolves the location, and reports what came back.
  Future<Object?> tapResolve(WidgetTester tester) async {
    Object? outcome;
    await tester.pumpWidget(
      await testHarness(
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async {
              try {
                outcome = await ref.resolveDeviceLocation();
              } on AppFailure catch (failure) {
                outcome = failure;
              }
            },
            child: const Text('Use My Location'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Use My Location'));
    // pumpAndSettle only advances while frames are scheduled, and none of this
    // is animated — the clock has to be pushed past the dialog delay by hand.
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    return outcome;
  }

  testWidgets('a slow permission dialog still resolves to a place', (
    tester,
  ) async {
    // Long enough that the provider would be disposed several times over if
    // nothing were holding it open.
    geolocator.permissionDelay = const Duration(seconds: 3);

    final outcome = await tapResolve(tester);

    expect(outcome, isA<Place>());
    expect((outcome! as Place).id, Place.currentLocationId);
    expect((outcome as Place).latitude, closeTo(37.77, 0.01));
  });

  testWidgets('a denied permission arrives as an AppFailure', (tester) async {
    geolocator.permission = LocationPermission.deniedForever;

    final outcome = await tapResolve(tester);

    expect(outcome, isA<AppFailure>());
    expect(outcome, const AppFailure.locationDenied(permanently: true));
  });

  testWidgets('location services switched off arrive as an AppFailure', (
    tester,
  ) async {
    geolocator.serviceEnabled = false;

    final outcome = await tapResolve(tester);

    expect(outcome, const AppFailure.locationDenied());
  });

  testWidgets('Search tells the user when the location is refused', (
    tester,
  ) async {
    geolocator.permission = LocationPermission.deniedForever;

    await tester.pumpWidget(await testHarness(const SearchScreen()));
    await tester.pump();
    await tester.tap(find.text('Use My Location'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text(
        'Location access is off. Enable it in Settings to use your location.',
      ),
      findsOneWidget,
      reason: 'the refusal never reached the user',
    );
  });
}

/// A geolocator that answers from memory, on a delay of the test's choosing.
class _FakeGeolocator extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Duration permissionDelay = Duration.zero;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async {
    await Future<void>.delayed(permissionDelay);
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.utc(2026),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}
