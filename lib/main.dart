import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/persistence/preferences.dart';
import 'features/home_widget/application/widget_refresh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The sky gradients run edge to edge behind the status bar. Dark glyphs are
  // only the starting point — every screen sets its own from the ground it
  // paints, through an `AnnotatedRegion`.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final prefs = await SharedPreferences.getInstance();

  // Asked for on every launch rather than once: this is what survives a
  // reboot, an app update, and the OS quietly dropping the work. Not awaited
  // — the first frame does not depend on it.
  unawaited(scheduleWidgetRefresh());

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AtmosFlowApp(),
    ),
  );
}
