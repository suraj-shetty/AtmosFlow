package com.surajshetty.atmos_flow

import io.flutter.embedding.android.FlutterActivity

/**
 * Nothing of its own to do.
 *
 * The app's reading reaches the home-screen widget through `home_widget`,
 * which is a plugin and so is registered on every engine — including the
 * headless one a background refresh runs in. A channel wired up here would
 * only exist while this activity does.
 */
class MainActivity : FlutterActivity()
