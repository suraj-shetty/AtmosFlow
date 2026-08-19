import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_providers.dart';
import 'routing/app_router.dart';

class AtmosFlowApp extends ConsumerWidget {
  const AtmosFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));

    return MaterialApp.router(
      title: 'AtmosFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appearance.themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
