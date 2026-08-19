package com.surajshetty.atmos_flow

import com.surajshetty.atmos_flow.widget.AtmosFlowWidgetProvider
import com.surajshetty.atmos_flow.widget.WidgetSnapshot
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /**
     * Carries the app's latest reading across to the home-screen widget.
     *
     * The widget draws whatever the app last left in SharedPreferences — it
     * cannot fetch a forecast of its own — so every reading the app resolves
     * is written straight back out, and the placed widgets repainted.
     */
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)

        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "publish") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                @Suppress("UNCHECKED_CAST")
                val values = call.arguments as? Map<String, String>
                if (values == null) {
                    result.error("bad-arguments", "publish expects a map of strings", null)
                    return@setMethodCallHandler
                }
                WidgetSnapshot.write(applicationContext, values)
                AtmosFlowWidgetProvider.refreshAll(applicationContext)
                result.success(null)
            }
    }

    private companion object {
        const val CHANNEL = "com.surajshetty.atmos_flow/widget"
    }
}
