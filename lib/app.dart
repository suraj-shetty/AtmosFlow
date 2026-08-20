import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home_widget/application/widget_publisher.dart';
import 'features/settings/application/settings_providers.dart';
import 'features/splash/presentation/splash_gate.dart';
import 'routing/app_router.dart';

class AtmosFlowApp extends ConsumerWidget {
  const AtmosFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));

    // Mirrors every forecast the app resolves out to the home-screen widgets.
    // Watched here rather than from Home so a refresh started anywhere still
    // reaches them.
    ref.watch(widgetMirrorProvider);

    return MaterialApp.router(
      title: 'AtmosFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appearance.themeMode,
      routerConfig: ref.watch(appRouterProvider),
      // The splash sits over the router, not inside it: the design asks for
      // one unbroken picture, and a route of its own would swap the sky out
      // rather than let it become today's.
      builder: (context, child) => SplashGate(child: child ?? const SizedBox()),
    );
  }
}
