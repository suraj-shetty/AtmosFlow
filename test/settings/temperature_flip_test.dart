import 'package:atmos_flow/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

/// The unit chip flips on its Y axis when the unit changes. The new value has
/// to arrive while the chip's face is turned away — swapping it on the first
/// frame shows the user the answer before the animation that is supposed to
/// deliver it, which reads as the flip lagging behind the tap.
void main() {
  // 22 °C is the chip's fixed sample; 22 °C is 71.6 °F.
  const celsius = '22°';
  const fahrenheit = '72°';

  testWidgets('the value swaps only once the chip is edge-on', (tester) async {
    await tester.pumpWidget(await testHarness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text(celsius), findsOneWidget);

    await tester.tap(find.text('°F'));

    // First frame of the flip: the chip is still square to the viewer.
    await tester.pump();
    expect(find.text(celsius), findsOneWidget);
    expect(find.text(fahrenheit), findsNothing);

    // 240ms of a 500ms flip — past halfway through the outbound turn, but
    // still short of the 90° crossing at ~239ms.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(celsius), findsOneWidget);
    expect(find.text(fahrenheit), findsNothing);

    // Past the crossing, with the face hidden.
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text(fahrenheit), findsOneWidget);
    expect(find.text(celsius), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text(fahrenheit), findsOneWidget);
  });

  testWidgets('with animations off the value changes immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      await testHarness(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('°F'));
    await tester.pump();
    expect(find.text(fahrenheit), findsOneWidget);
    expect(find.text(celsius), findsNothing);
  });
}
